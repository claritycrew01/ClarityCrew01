const admin = require('firebase-admin');
const { readFileSync } = require('fs');
const { searchAllKinds, bestVideoUrl, sanitizeId, formatDuration, sleep } = require('./kolibri_fetch.cjs');

const BASE_URL = process.env.KOLIBRI_BASE_URL ||
  'https://contentworkshop.learningequality.org/api/public/v1';
const MAX_RETRIES = 3;

async function ensureSubject(db, id, name, iconKey, color) {
  const doc = db.collection('subjects').doc(id);
  const snap = await doc.get();
  if (snap.exists) {
    console.log(`  subject "${name}" already exists`);
    return true;
  }
  await doc.set({ id, name, iconKey, color });
  console.log(`  created subject "${name}"`);
  return true;
}

async function ensureChapter(db, id, subjectId, title, order) {
  const doc = db.collection('chapters').doc(id);
  const snap = await doc.get();
  if (snap.exists) {
    console.log(`  chapter "${title}" already exists`);
    return true;
  }
  await doc.set({ id, subjectId, title, order });
  console.log(`  created chapter "${title}"`);
  return true;
}

async function upsertImportJob(db, job) {
  await db.collection('content_imports').doc(job.id).set(job, { merge: true });
}

async function runImport() {
  const saJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!saJson) {
    console.error('FATAL: FIREBASE_SERVICE_ACCOUNT env var not set');
    process.exit(1);
  }

  const sa = JSON.parse(saJson);
  console.log('Project ID from service account:', sa.project_id);
  admin.initializeApp({
    credential: admin.credential.cert(sa),
    projectId: sa.project_id,
  });
  const db = admin.firestore();
  db.settings({ preferRest: true });

  // Probe: list collections to verify connectivity
  try {
    const collections = await db.listCollections();
    console.log('Firestore connected. Collections:', collections.map((c) => c.id).join(', ') || '(none)');
  } catch (probeErr) {
    console.error('Firestore probe failed:', probeErr.message);
    process.exit(1);
  }

  // Load topic mappings: try Firestore first, then JSON fallback
  let mappings = [];
  try {
    const snap = await db.collection('topic_mappings')
      .where('enabled', '==', true)
      .get();
    if (!snap.empty) {
      mappings = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      console.log(`Loaded ${mappings.length} topic mappings from Firestore`);
    }
  } catch (e) {
    console.warn(`Firestore read failed: ${e.message}, trying JSON fallback`);
  }

  if (mappings.length === 0) {
    const raw = readFileSync('tool/seed_data/topic_mappings.json', 'utf8');
    mappings = JSON.parse(raw);
    console.log(`Loaded ${mappings.length} topic mappings from JSON fallback`);
  }

  let totalFound = 0;
  let totalImported = 0;
  let totalFailed = 0;

  for (const mapping of mappings) {
    const queryLabel = `${mapping.subject}/${mapping.chapter || 'general'}`;
    console.log(`\n--- ${queryLabel} ---`);

    for (const query of mapping.searchQueries) {
      const jobId = `${sanitizeId(query)}_${Date.now()}`;
      await upsertImportJob(db, {
        id: jobId, topicQuery: query, contentType: 'mixed',
        sourceSystem: 'kolibri', status: 'in_progress',
        retryCount: 0, maxRetries: MAX_RETRIES,
        createdAt: new Date().toISOString(),
        startedAt: new Date().toISOString(),
        logEntries: [`Searching Kolibri for "${query}"`],
      });

      let nodes = [];
      let retries = 0;
      while (retries <= MAX_RETRIES) {
        try {
          nodes = await searchAllKinds(query, BASE_URL);
          break;
        } catch (e) {
          retries++;
          if (retries > MAX_RETRIES) {
            console.error(`  FAILED after ${MAX_RETRIES} retries: "${query}" — ${e.message}`);
            await upsertImportJob(db, {
              id: jobId, status: 'failed',
              errorMessage: e.message,
              completedAt: new Date().toISOString(),
            });
            totalFailed++;
            break;
          }
          const delay = 2000 * retries;
          console.warn(`  retry ${retries}/${MAX_RETRIES} for "${query}" in ${delay}ms...`);
          await sleep(delay);
        }
      }
      if (nodes.length === 0) {
        await upsertImportJob(db, { id: jobId, status: 'completed', completedAt: new Date().toISOString() });
        continue;
      }

      totalFound += nodes.length;
      const subjectId = sanitizeId(mapping.subject);
      const chapterSlug = mapping.chapter ? sanitizeId(mapping.chapter) : 'general';

      // Auto-create subject if needed
      await ensureSubject(db, subjectId, mapping.subject, mapping.iconKey || 'school_outlined', mapping.color || '#4A90D9');

      // Auto-create chapter if needed
      if (mapping.chapter) {
        const chapterId = `${subjectId}_${chapterSlug}`;
        await ensureChapter(db, chapterId, subjectId, mapping.chapter, 0);
      }

      let imported = 0;
      let failed = 0;
      for (const node of nodes) {
        try {
          const ok = await importNode(db, node, mapping, subjectId, chapterSlug, jobId);
          if (ok) imported++;
          else failed++;
        } catch (e) {
          console.error(`  error importing ${node.title || node.id}: ${e.message}`);
          failed++;
        }
      }

      await upsertImportJob(db, {
        id: jobId, status: 'completed', completedAt: new Date().toISOString(),
        logEntries: [`Imported ${imported}, failed ${failed} for "${query}"`],
      });
      totalImported += imported;
      totalFailed += failed;
      console.log(`  "${query}": ${imported} imported, ${failed} failed`);
    }
  }

  console.log(`\n=== Summary ===`);
  console.log(`Found: ${totalFound} | Imported: ${totalImported} | Failed: ${totalFailed}`);
  process.exit(0);
}

async function importNode(db, node, mapping, subjectId, chapterSlug, jobId) {
  switch (node.kind) {
    case 'video': return importVideo(db, node, mapping, chapterSlug, jobId);
    case 'exercise': return importLesson(db, node, mapping, subjectId, chapterSlug, jobId, 'guided_practice');
    case 'document': return importLesson(db, node, mapping, subjectId, chapterSlug, jobId, 'micro_lesson');
    default:
      console.log(`  skip kind="${node.kind}": ${node.title || node.id}`);
      return false;
  }
}

async function importVideo(db, node, mapping, chapterSlug, jobId) {
  const files = node.files || [];
  const videoUrl = bestVideoUrl(files);
  if (!videoUrl) {
    console.warn(`  no playable URL for video: ${node.title}`);
    return false;
  }

  const videoId = `kolibri_video_${node.id}`;
  const existing = await db.collection('videos').doc(videoId).get();
  if (existing.exists) {
    console.log(`  video already exists: ${node.title}`);
    return true;
  }

  const dur = node.duration ? formatDuration(node.duration) : '';
  await db.collection('videos').doc(videoId).set({
    id: videoId,
    title: node.title || '',
    description: node.description || '',
    duration: dur,
    durationSeconds: node.duration || 0,
    subject: mapping.subject,
    chapter: mapping.chapter || '',
    keyPoints: [],
    chapters: [],
    difficulty: mapping.difficulty || 'beginner',
    assetPath: videoUrl,
    linkedLessonId: '',
    sourceId: node.id,
    sourceSystem: 'kolibri',
  });

  console.log(`  imported video: ${node.title}`);
  return true;
}

async function importLesson(db, node, mapping, subjectId, chapterSlug, jobId, contentType) {
  const lessonId = `kolibri_${contentType}_${node.id}`;
  const existing = await db.collection('lessons').doc(lessonId).get();
  if (existing.exists) {
    console.log(`  ${contentType} already exists: ${node.title}`);
    return true;
  }

  await db.collection('lessons').doc(lessonId).set({
    id: lessonId,
    title: node.title || '',
    description: node.description || '',
    contentType: contentType,
    difficulty: mapping.difficulty || 'beginner',
    estimatedDurationSeconds: 600,
    tags: [mapping.subject, mapping.chapter || 'general', 'kolibri', contentType],
    body: node.description || `Content imported from Kolibri: ${node.title}`,
    subject: mapping.subject,
    chapter: mapping.chapter || '',
    chapterId: chapterSlug,
    videoId: '',
    metadata: {
      sourceSystem: 'kolibri',
      sourceId: node.id,
      importJobId: jobId,
      importStatus: 'imported',
    },
    quizOptions: [],
    correctOptionIndex: null,
    flashcards: [],
    sourceId: node.id,
    sourceSystem: 'kolibri',
  });

  console.log(`  imported ${contentType}: ${node.title}`);
  return true;
}

runImport().catch((e) => {
  console.error('FATAL:', e);
  process.exit(1);
});
