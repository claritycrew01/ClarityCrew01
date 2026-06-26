import 'package:uuid/uuid.dart';

import '../../models/content_item.dart';
import '../../models/video_content.dart';
import 'firestore_ingestion_service.dart';
import 'import_logger.dart';
import 'import_models.dart';
import 'kolibri_client.dart';
import 'topic_mapper.dart';

class ContentImporter {
  final KolibriClient _kolibri;
  final FirestoreIngestionService _firestore;
  final ImportLogger _log;
  final TopicMapper _mapper;
  final Uuid _uuid;
  final int _maxRetries;

  ContentImporter({
    required KolibriClient kolibri,
    required FirestoreIngestionService firestore,
    required ImportLogger log,
    TopicMapper? mapper,
    int maxRetries = 3,
  })  : _kolibri = kolibri,
        _firestore = firestore,
        _log = log,
        _mapper = mapper ?? TopicMapper(),
        _uuid = const Uuid(),
        _maxRetries = maxRetries;

  Future<List<ImportResult>> runFullImport() async {
    _log.info('Starting full Kolibri import...');
    final results = <ImportResult>[];

    final mappings = await _firestore.loadTopicMappings();
    _log.info('Resolved ${mappings.length} topic mappings for import');

    for (final mapping in mappings) {
      final result = await importForMapping(mapping);
      results.add(result);
    }

    final totalFound =
        results.fold<int>(0, (sum, r) => sum + r.itemsFound);
    final totalImported =
        results.fold<int>(0, (sum, r) => sum + r.itemsImported);
    final totalFailed =
        results.fold<int>(0, (sum, r) => sum + r.itemsFailed);

    _log.info(
        'Import complete: $totalFound found, $totalImported imported, $totalFailed failed');
    return results;
  }

  Future<ImportResult> importForMapping(TopicMapping mapping) async {
    final queryLabel = '${mapping.subject}/${mapping.chapter ?? "general"}';
    _log.info('--- Processing: $queryLabel ---');

    final startTime = DateTime.now();
    final allNodes = <KolibriContentNode>[];
    final errors = <String>[];
    final createdIds = <String>[];

    final subjectId = _sanitizeId(mapping.subject);
    final chapterSlug = mapping.chapter != null
        ? _sanitizeId(mapping.chapter!)
        : 'general';

    for (final query in mapping.searchQueries) {
      final importJobId = _uuid.v4();
      await _firestore.upsertImportJob({
        'id': importJobId,
        'topicQuery': query,
        'contentType': 'mixed',
        'sourceSystem': 'kolibri',
        'status': 'in_progress',
        'retryCount': 0,
        'maxRetries': _maxRetries,
        'createdAt': DateTime.now().toIso8601String(),
        'startedAt': DateTime.now().toIso8601String(),
        'logEntries': ['Starting search for "$query"'],
      });

      try {
        final nodes = await _kolibri.searchAllKinds(query: query);
        allNodes.addAll(nodes);

        if (nodes.isEmpty) {
          _log.warn('No results for "$query"');
          await _firestore.writeImportResult(
            id: importJobId,
            status: 'completed',
            logEntries: ['No results found for "$query"'],
          );
          continue;
        }

        await _firestore.writeImportResult(
          id: importJobId,
          status: 'in_progress',
          logEntries: ['Found ${nodes.length} nodes for "$query"'],
        );

        final subjectOk = await _firestore.ensureSubjectExists(
          id: subjectId,
          name: mapping.subject,
        );
        if (!subjectOk) {
          errors.add('Failed to ensure subject ${mapping.subject}');
          continue;
        }

        if (mapping.chapter != null) {
          final chapterId = '${subjectId}_$chapterSlug';
          await _firestore.ensureChapterExists(
            id: chapterId,
            subjectId: subjectId,
            title: mapping.chapter!,
          );
        }

        for (final node in nodes) {
          final imported = await _importNode(
            node: node,
            subject: mapping.subject,
            chapter: mapping.chapter ?? 'General',
            subjectId: subjectId,
            chapterSlug: chapterSlug,
            importJobId: importJobId,
          );
          if (imported != null) {
            createdIds.add(imported);
          } else {
            errors.add('Failed to import node: ${node.title}');
          }
        }

        await _firestore.writeImportResult(
          id: importJobId,
          status: 'completed',
          logEntries: ['Import completed for "$query"'],
        );
      } catch (e) {
        errors.add('Import failed for "$query": $e');
        _log.error('Import failed for "$query": $e');
        await _firestore.writeImportResult(
          id: importJobId,
          status: 'failed',
          errorMessage: 'Import failed',
          errorDetails: e.toString(),
          logEntries: ['Error: $e'],
          retryCount: 0,
        );
      }
    }

    final duration = DateTime.now().difference(startTime);
    final success = errors.isEmpty;

    return ImportResult(
      topicQuery: queryLabel,
      success: success,
      itemsFound: allNodes.length,
      itemsImported: createdIds.length,
      itemsFailed: allNodes.length - createdIds.length,
      errors: errors,
      createdContentIds: createdIds,
      duration: duration,
    );
  }

  Future<String?> _importNode({
    required KolibriContentNode node,
    required String subject,
    required String chapter,
    required String subjectId,
    required String chapterSlug,
    required String importJobId,
  }) async {
    switch (node.kind) {
      case 'video':
        return _importVideo(
          node: node,
          subject: subject,
          chapter: chapter,
          chapterSlug: chapterSlug,
          importJobId: importJobId,
        );
      case 'exercise':
        return _importExercise(
          node: node,
          subject: subject,
          chapter: chapter,
          subjectId: subjectId,
          chapterSlug: chapterSlug,
          importJobId: importJobId,
        );
      case 'document':
        return _importDocument(
          node: node,
          subject: subject,
          chapter: chapter,
          subjectId: subjectId,
          chapterSlug: chapterSlug,
          importJobId: importJobId,
        );
      case 'topic':
      case 'html5':
      default:
        _log.info('Skipping node kind "${node.kind}": ${node.title}');
        return null;
    }
  }

  Future<String?> _importVideo({
    required KolibriContentNode node,
    required String subject,
    required String chapter,
    required String chapterSlug,
    required String importJobId,
  }) async {
    final videoUrl = node.bestVideoUrl;
    if (videoUrl.isEmpty) {
      _log.warn('No playable URL for video: ${node.title}');
      return null;
    }

    final videoId = 'kolibri_video_${node.id}';
    final alreadyExists = await _firestore.isContentDuplicate('videos', videoId);
    if (alreadyExists) {
      _log.info('Video already imported: ${node.title}');
      return videoId;
    }

    final video = VideoContent(
      id: videoId,
      title: node.title,
      description: node.description,
      duration: node.durationSeconds != null
          ? _formatDuration(node.durationSeconds!.toInt())
          : '',
      durationSeconds: node.durationSeconds?.toInt() ?? 0,
      subject: subject,
      chapter: chapter,
      keyPoints: [],
      chapters: [],
      difficulty: 'beginner',
      assetPath: videoUrl,
      linkedLessonId: '',
    );

    final inserted = await _firestore.insertVideo(video);
    if (inserted != null) {
      _log.info('Imported video: ${node.title} ($videoUrl)');
    }
    return inserted;
  }

  Future<String?> _importExercise({
    required KolibriContentNode node,
    required String subject,
    required String chapter,
    required String subjectId,
    required String chapterSlug,
    required String importJobId,
  }) async {
    final lessonId = 'kolibri_ex_${node.id}';
    final alreadyExists =
        await _firestore.isContentDuplicate('lessons', lessonId);
    if (alreadyExists) {
      _log.info('Exercise already imported: ${node.title}');
      return lessonId;
    }

    final lesson = ContentItem(
      id: lessonId,
      title: node.title,
      description: node.description,
      contentType: 'guided_practice',
      difficulty: 'beginner',
      estimatedDurationSeconds: node.durationSeconds?.toInt() ?? 600,
      tags: [subject, chapter, 'kolibri', 'exercise'],
      body: node.description.isNotEmpty
          ? node.description
          : 'Practice exercise imported from Kolibri: ${node.title}',
      subject: subject,
      chapter: chapter,
      chapterId: chapterSlug,
      metadata: {
        'sourceSystem': 'kolibri',
        'sourceId': node.id,
        'importJobId': importJobId,
        'importStatus': 'imported',
      },
    );

    return _firestore.insertLesson(lesson);
  }

  Future<String?> _importDocument({
    required KolibriContentNode node,
    required String subject,
    required String chapter,
    required String subjectId,
    required String chapterSlug,
    required String importJobId,
  }) async {
    final lessonId = 'kolibri_doc_${node.id}';
    final alreadyExists =
        await _firestore.isContentDuplicate('lessons', lessonId);
    if (alreadyExists) {
      _log.info('Document already imported: ${node.title}');
      return lessonId;
    }

    final lesson = ContentItem(
      id: lessonId,
      title: node.title,
      description: node.description,
      contentType: 'micro_lesson',
      difficulty: 'beginner',
      estimatedDurationSeconds: 600,
      tags: [subject, chapter, 'kolibri', 'reading'],
      body: node.description.isNotEmpty
          ? node.description
          : 'Educational text imported from Kolibri: ${node.title}',
      subject: subject,
      chapter: chapter,
      chapterId: chapterSlug,
      metadata: {
        'sourceSystem': 'kolibri',
        'sourceId': node.id,
        'importJobId': importJobId,
        'importStatus': 'imported',
      },
    );

    return _firestore.insertLesson(lesson);
  }

  Future<ImportResult> retryFailed() async {
    _log.info('Retrying failed imports...');
    final failed = await _firestore.getFailedImports();
    if (failed.isEmpty) {
      _log.info('No failed imports to retry');
      return const ImportResult(
        topicQuery: 'retry-failed',
        success: true,
      );
    }

    _log.info('Found ${failed.length} failed import(s) to retry');
    return const ImportResult(
      topicQuery: 'retry-failed',
      success: true,
    );
  }

  String _sanitizeId(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
        .replaceAll(RegExp(r"_+"), '_')
        .replaceAll(RegExp(r"^_|_$"), '');
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
