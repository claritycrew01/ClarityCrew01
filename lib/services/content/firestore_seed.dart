import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

/// Seeds Firestore with the bundled JSON data.
///
/// Run once from a dev build after setting up Firebase:
///
///   flutter run -t lib/services/content/firestore_seed.dart
///
/// Creates collections: subjects, chapters, lessons (with flashcards
/// subcollection), videos.  All doc IDs match the JSON `id` fields.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instanceFor(databaseId: 'claritycrew');

  await _seed(firestore, 'subjects', 'assets/content/subjects.json');
  await _seed(firestore, 'chapters', 'assets/content/chapters.json');

  final lessonsList =
      jsonDecode(await rootBundle.loadString('assets/content/lessons.json'))
          as List<dynamic>;

  for (final raw in lessonsList) {
    final lesson = Map<String, dynamic>.from(raw as Map);
    final flashcards =
        List<Map<String, dynamic>>.from(lesson.remove('flashcards') as List? ?? []);
    final id = lesson['id'] as String;
    await firestore.collection('lessons').doc(id).set(lesson);
    for (final fc in flashcards) {
      await firestore
          .collection('lessons')
          .doc(id)
          .collection('flashcards')
          .doc(fc['id'] as String)
          .set(fc);
    }
  }

  await _seed(firestore, 'videos', 'assets/content/videos.json');

  // ignore: avoid_print
  print('Firestore seeded successfully.');
}

Future<void> _seed(
  FirebaseFirestore firestore,
  String collection,
  String assetPath,
) async {
  final json = await rootBundle.loadString(assetPath);
  final items = jsonDecode(json) as List<dynamic>;
  for (final raw in items) {
    final item = raw as Map<String, dynamic>;
    await firestore.collection(collection).doc(item['id'] as String).set(item);
  }
}
