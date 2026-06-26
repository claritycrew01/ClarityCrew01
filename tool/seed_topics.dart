import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

/// Seeds Firestore with topic mappings for the Kolibri ingestion pipeline.
///
/// Run once from a dev build after Firebase is configured:
///
///   flutter run -t tool/seed_topics.dart
///
/// Creates collection: topic_mappings
/// Each doc matches a subject/chapter the pipeline should search Kolibri for.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;
  final json = await File('tool/seed_data/topic_mappings.json').readAsString();
  final mappings = jsonDecode(json) as List<dynamic>;

  for (final raw in mappings) {
    final map = raw as Map<String, dynamic>;
    final id = map['id'] as String;
    await firestore.collection('topic_mappings').doc(id).set(map);
    print('  Created: $id');
  }

  print('');
  print('Seeded ${mappings.length} topic mappings.');
  print('');
  print('Run the ingestion pipeline:');
  print('  flutter run -t tool/ingestion_cli.dart');
  exit(0);
}
