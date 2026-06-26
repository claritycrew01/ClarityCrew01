import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../lib/services/ingestion/content_importer.dart';
import '../lib/services/ingestion/firestore_ingestion_service.dart';
import '../lib/services/ingestion/import_logger.dart';
import '../lib/services/ingestion/kolibri_client.dart';
import '../lib/services/ingestion/topic_mapper.dart';

/// Kolibri content ingestion CLI.
///
/// Usage:
///   flutter run -t tool/ingestion_cli.dart
///
/// This initializes Firebase, runs the Kolibri import, and exits.
///
/// Flags (pass via --dart-define):
///   --dart-define=KOLIBRI_BASE_URL=https://custom-instance.example.org/api/public/v1
///   --dart-define=QUIET=true   suppress info/warn output
///   --dart-define=RETRY_FAILED=true   retry previously failed imports
///   --dart-define=SEED_MAPPINGS=true   write default topic mappings to Firestore

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final quiet = const String.fromEnvironment('QUIET') == 'true';
  final retryFailed = const String.fromEnvironment('RETRY_FAILED') == 'true';
  final seedMappings = const String.fromEnvironment('SEED_MAPPINGS') == 'true';
  final kolibriUrl = const String.fromEnvironment(
    'KOLIBRI_BASE_URL',
    defaultValue: 'https://contentworkshop.learningequality.org/api/public/v1',
  );

  final log = ImportLogger(id: 'ingestion-cli', quiet: quiet);

  stdout.writeln('=== ClarityCrew Kolibri Content Ingestion ===');
  stdout.writeln('Kolibri API: $kolibriUrl');
  if (retryFailed) stdout.writeln('Mode: retry failed');
  stdout.writeln();

  // Initialize Firebase (same project as the app)
  log.info('Initializing Firebase...');
  try {
    await Firebase.initializeApp();
    log.info('Firebase initialized.');
  } catch (e) {
    log.error('Firebase init failed: $e');
    stderr.writeln(
        'ERROR: Cannot proceed without Firebase. Make sure Firebase is configured.');
    exit(1);
  }

  // Build pipeline
  final kolibri = KolibriClient(
    baseUrl: kolibriUrl,
    log: log.subLogger('kolibri'),
  );
  final firestore = FirestoreIngestionService(
    log: log.subLogger('firestore'),
  );
  final importer = ContentImporter(
    kolibri: kolibri,
    firestore: firestore,
    log: log,
  );

  // Seed default topic mappings if requested
  if (seedMappings) {
    stdout.writeln('Seeding default topic mappings to Firestore...');
    await firestore.seedDefaultTopicMappings();
    stdout.writeln('Done.');
    exit(0);
  }

  // Run import
  try {
    if (retryFailed) {
      await importer.retryFailed();
    } else {
      final results = await importer.runFullImport();
      stdout.writeln();
      stdout.writeln('=== Results ===');
      for (final r in results) {
        final icon = r.success ? 'OK' : 'FAIL';
        stdout.writeln(
            '  [$icon] ${r.topicQuery}: ${r.itemsImported}/${r.itemsFound} imported, ${r.itemsFailed} failed (${r.duration.inSeconds}s)');
      }
    }
  } catch (e) {
    log.error('Import crashed: $e');
    stderr.writeln('FATAL: $e');
    exit(1);
  } finally {
    await kolibri.dispose();
  }

  stdout.writeln();
  stdout.writeln('=== Ingestion complete ===');
  exit(0);
}
