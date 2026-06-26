const { readFileSync } = require('fs');
const admin = require('firebase-admin');

async function main() {
  const saJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!saJson) {
    console.error('FATAL: FIREBASE_SERVICE_ACCOUNT env var not set');
    process.exit(1);
  }

  const sa = JSON.parse(saJson);
  admin.initializeApp({ credential: admin.credential.cert(sa) });
  const db = admin.firestore();

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
