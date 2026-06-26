const { readFileSync } = require('fs');
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

async function main() {
  const saJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!saJson) {
    console.error('FATAL: FIREBASE_SERVICE_ACCOUNT env var not set');
    process.exit(1);
  }

  const sa = JSON.parse(saJson);
  console.log('Project ID:', sa.project_id);

  admin.initializeApp({
    credential: admin.credential.cert(sa),
    projectId: sa.project_id,
  });
  const db = getFirestore(admin.app(), 'claritycrew');

  const collections = await db.listCollections();
  console.log('Connected. Collections:', collections.map((c) => c.id).join(', ') || '(none)');

  const raw = readFileSync('tool/seed_data/topic_mappings.json', 'utf8');
  const mappings = JSON.parse(raw);

  const subjects = {};
  const chapters = [];
  const lessons = [];
  const videos = [];

  for (const m of mappings) {
    if (!subjects[m.subject]) {
      subjects[m.subject] = {
        id: m.subject.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/_+/g, '_'),
        name: m.subject,
        iconKey: m.iconKey || 'school_outlined',
        color: m.color || '#4A90D9',
      };
    }

    if (m.chapter) {
      const sid = subjects[m.subject].id;
      const chSlug = m.chapter.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/_+/g, '_');
      chapters.push({
        id: `${sid}_${chSlug}`,
        subjectId: sid,
        title: m.chapter,
        order: 0,
      });
    }

    for (const sq of m.searchQueries) {
      const qSlug = sq.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/_+/g, '_');
      const lessonId = `gen_lesson_${qSlug}`;
      lessons.push({
        id: lessonId,
        title: sq.charAt(0).toUpperCase() + sq.slice(1),
        description: `Learn about ${sq}. This lesson covers key concepts and practice exercises.`,
        contentType: 'micro_lesson',
        difficulty: m.difficulty || 'beginner',
        estimatedDurationSeconds: 600,
        tags: [m.subject, m.chapter || 'general', 'generated'],
        body: `<p>Welcome to this lesson on <strong>${sq}</strong>.</p><p>Work through the material below to master this topic.</p>`,
        subject: m.subject,
        chapter: m.chapter || '',
        chapterId: chapters.length > 0 ? chapters[chapters.length - 1].id : 'general',
        videoId: `gen_video_${qSlug}`,
        metadata: { sourceSystem: 'generated', importStatus: 'seeded' },
        quizOptions: [],
        correctOptionIndex: null,
        flashcards: [],
        sourceId: qSlug,
        sourceSystem: 'generated',
      });

      videos.push({
        id: `gen_video_${qSlug}`,
        title: `Video: ${sq.charAt(0).toUpperCase() + sq.slice(1)}`,
        description: `An overview of ${sq}`,
        duration: '5:00',
        durationSeconds: 300,
        subject: m.subject,
        chapter: m.chapter || '',
        keyPoints: [],
        chapters: [],
        difficulty: m.difficulty || 'beginner',
        assetPath: '',
        linkedLessonId: lessonId,
        sourceId: qSlug,
        sourceSystem: 'generated',
      });
    }
  }

  // Write subjects
  let count = 0;
  for (const [name, s] of Object.entries(subjects)) {
    await db.collection('subjects').doc(s.id).set(s);
    count++;
    console.log(`  subject[${count}]: ${s.name} (${s.id})`);
  }

  // Write chapters
  const seenChapters = new Set();
  for (const ch of chapters) {
    if (seenChapters.has(ch.id)) continue;
    seenChapters.add(ch.id);
    await db.collection('chapters').doc(ch.id).set(ch);
    count++;
    console.log(`  chapter[${count}]: ${ch.title} (${ch.id})`);
  }

  // Write lessons
  for (const l of lessons) {
    const existing = await db.collection('lessons').doc(l.id).get();
    if (existing.exists) continue;
    await db.collection('lessons').doc(l.id).set(l);
    count++;
    console.log(`  lesson[${count}]: ${l.title} (${l.id})`);
  }

  // Write videos
  for (const v of videos) {
    const existing = await db.collection('videos').doc(v.id).get();
    if (existing.exists) continue;
    await db.collection('videos').doc(v.id).set(v);
    count++;
    console.log(`  video[${count}]: ${v.title} (${v.id})`);
  }

  console.log(`\nDone. Created ${count} documents total.`);
  process.exit(0);
}

main().catch((e) => {
  console.error('FATAL:', e);
  process.exit(1);
});
