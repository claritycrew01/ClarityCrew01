const { readFileSync } = require('fs');
const admin = require('firebase-admin');

async function main() {
  const saJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!saJson) {
    console.error('FATAL: FIREBASE_SERVICE_ACCOUNT env var not set');
    process.exit(1);
  }

  const sa = JSON.parse(saJson);
  console.log('Project ID from service account:', sa.project_id);
  console.log('Client email:', sa.client_email);

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
    console.error('Full:', probeErr);
    process.exit(1);
  }

  const raw = readFileSync('tool/seed_data/topic_mappings.json', 'utf8');
  const mappings = JSON.parse(raw);

  let count = 0;
  for (const mapping of mappings) {
    const id = mapping.id;
    delete mapping.id;
    await db.collection('topic_mappings').doc(id).set(mapping);
    count++;
    console.log(`  [${count}/${mappings.length}] Created: ${id}`);
  }

  console.log(`\nDone. Seeded ${count} topic mappings.`);
  process.exit(0);
}

main().catch((e) => {
  console.error('FATAL:', e);
  process.exit(1);
});
