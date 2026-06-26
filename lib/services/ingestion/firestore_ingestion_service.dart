import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/content_item.dart';
import '../../models/video_content.dart';
import 'import_logger.dart';
import 'topic_mapper.dart';

class FirestoreIngestionService {
  final FirebaseFirestore _firestore;
  final ImportLogger _log;

  FirestoreIngestionService({
    FirebaseFirestore? firestore,
    required ImportLogger log,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _log = log;

  Future<bool> ensureSubjectExists({
    required String id,
    required String name,
    String iconKey = 'school_outlined',
    String color = '#4A90D9',
  }) async {
    try {
      final doc = await _firestore.collection('subjects').doc(id).get();
      if (doc.exists) {
        _log.info('Subject "$name" already exists');
        return true;
      }
      await _firestore.collection('subjects').doc(id).set({
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'color': color,
      });
      _log.info('Created subject "$name" (id=$id)');
      return true;
    } catch (e) {
      _log.error('Failed to create subject "$name": $e');
      return false;
    }
  }

  Future<bool> ensureChapterExists({
    required String id,
    required String subjectId,
    required String title,
    int order = 0,
  }) async {
    try {
      final doc = await _firestore.collection('chapters').doc(id).get();
      if (doc.exists) {
        _log.info('Chapter "$title" already exists');
        return true;
      }
      await _firestore.collection('chapters').doc(id).set({
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'order': order,
      });
      _log.info('Created chapter "$title" (id=$id)');
      return true;
    } catch (e) {
      _log.error('Failed to create chapter "$title": $e');
      return false;
    }
  }

  Future<String?> insertLesson(ContentItem lesson) async {
    try {
      final map = lesson.toJson();
      map.remove('flashcards');
      await _firestore.collection('lessons').doc(lesson.id).set(map);

      for (final flashcard in lesson.flashcards) {
        await _firestore
            .collection('lessons')
            .doc(lesson.id)
            .collection('flashcards')
            .doc(flashcard.id)
            .set(flashcard.toJson());
      }
      _log.info('Inserted lesson "${lesson.title}" (id=${lesson.id})');
      return lesson.id;
    } catch (e) {
      _log.error('Failed to insert lesson "${lesson.title}": $e');
      return null;
    }
  }

  Future<String?> insertVideo(VideoContent video) async {
    try {
      await _firestore.collection('videos').doc(video.id).set(video.toJson());
      _log.info('Inserted video "${video.title}" (id=${video.id})');
      return video.id;
    } catch (e) {
      _log.error('Failed to insert video "${video.title}": $e');
      return null;
    }
  }

  Future<String?> upsertImportJob(Map<String, dynamic> jobData) async {
    try {
      final id = jobData['id'] as String;
      await _firestore
          .collection('content_imports')
          .doc(id)
          .set(jobData, SetOptions(merge: true));
      return id;
    } catch (e) {
      _log.error('Failed to upsert import job: $e');
      return null;
    }
  }

  Future<void> writeImportResult({
    required String id,
    required String status,
    String? errorMessage,
    String? errorDetails,
    List<String>? logEntries,
    int? retryCount,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (errorDetails != null) 'errorDetails': errorDetails,
      if (logEntries != null) 'logEntries': logEntries,
      if (retryCount != null) 'retryCount': retryCount,
    };
    if (status == 'completed' || status == 'failed') {
      data['completedAt'] = DateTime.now().toIso8601String();
    }
    try {
      await _firestore
          .collection('content_imports')
          .doc(id)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      _log.error('Failed to write import result for $id: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFailedImports() async {
    try {
      final snapshot = await _firestore
          .collection('content_imports')
          .where('status', whereIn: ['failed', 'partial'])
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      _log.error('Failed to query failed imports: $e');
      return [];
    }
  }

  Future<bool> isContentDuplicate(String collection, String id) async {
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Future<List<TopicMapping>> loadTopicMappings() async {
    try {
      final snapshot = await _firestore
          .collection('topic_mappings')
          .where('enabled', isEqualTo: true)
          .get();
      if (snapshot.docs.isEmpty) {
        _log.info('No topic_mappings in Firestore, using defaults');
        return TopicMapper.defaultMappings;
      }
      final mappings = snapshot.docs
          .map((d) => TopicMapping.fromJson(
              d.data() as Map<String, dynamic>))
          .toList();
      _log.info('Loaded ${mappings.length} topic mappings from Firestore');
      return mappings;
    } catch (e) {
      _log.warn('Failed to load topic_mappings from Firestore: $e');
      return TopicMapper.defaultMappings;
    }
  }

  Future<void> writeTopicMapping(TopicMapping mapping) async {
    try {
      final id = mapping.id.isNotEmpty
          ? mapping.id
          : TopicMapper.generateId(mapping.subject, mapping.chapter);
      await _firestore
          .collection('topic_mappings')
          .doc(id)
          .set(mapping.toJson());
      _log.info('Wrote topic mapping: $id');
    } catch (e) {
      _log.error('Failed to write topic mapping: $e');
    }
  }

  Future<void> seedDefaultTopicMappings() async {
    final existing = await _firestore
        .collection('topic_mappings')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    _log.info('Seeding default topic mappings to Firestore...');
    for (final mapping in TopicMapper.defaultMappings) {
      await writeTopicMapping(mapping);
    }
    _log.info(
        'Seeded ${TopicMapper.defaultMappings.length} topic mappings');
  }
}
