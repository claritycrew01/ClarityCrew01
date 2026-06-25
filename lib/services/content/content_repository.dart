import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/content_item.dart';
import '../../models/subject_data.dart';
import '../../models/video_content.dart';
import 'subject_icon_registry.dart';

class ContentRepository {
  ContentRepository._();

  static final ContentRepository instance = ContentRepository._();

  static List<ContentItem> _lessons = [];
  static List<VideoContent> _videos = [];
  static List<_SubjectRecord> _subjects = [];
  static List<_ChapterRecord> _chapters = [];
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    final subjectsJson =
        await rootBundle.loadString('assets/content/subjects.json');
    final chaptersJson =
        await rootBundle.loadString('assets/content/chapters.json');
    final lessonsJson =
        await rootBundle.loadString('assets/content/lessons.json');
    final videosJson =
        await rootBundle.loadString('assets/content/videos.json');

    _subjects = (jsonDecode(subjectsJson) as List<dynamic>)
        .map((e) => _SubjectRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    _chapters = (jsonDecode(chaptersJson) as List<dynamic>)
        .map((e) => _ChapterRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    _lessons = (jsonDecode(lessonsJson) as List<dynamic>)
        .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
        .toList();
    _videos = (jsonDecode(videosJson) as List<dynamic>)
        .map((e) => VideoContent.fromJson(e as Map<String, dynamic>))
        .toList();

    _initialized = true;
  }

  static List<ContentItem> getAll() => List.unmodifiable(_lessons);

  static ContentItem getById(String id) => _lessons.firstWhere(
        (l) => l.id == id,
        orElse: () => _lessons.first,
      );

  static ContentItem? findById(String id) {
    for (final lesson in _lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  static List<ContentItem> getByTags(List<String> tags) => _lessons
      .where((l) => l.tags.any((t) => tags.contains(t)))
      .toList();

  static List<ContentItem> getByDifficulty(String difficulty) =>
      _lessons.where((l) => l.difficulty == difficulty).toList();

  static List<ContentItem> getByType(String contentType) {
    if (contentType == 'lesson') {
      return _lessons
          .where((l) =>
              l.contentType != 'quiz' &&
              l.contentType != 'flashcard' &&
              l.contentType != 'video')
          .toList();
    }
    return _lessons.where((l) => l.contentType == contentType).toList();
  }

  static List<ContentItem> getBySubject(String subject) =>
      _lessons.where((l) => l.subject == subject).toList();

  static List<String> getAllSubjectNames() =>
      _lessons.map((l) => l.subject).toSet().toList()..sort();

  static List<String> getChaptersForSubject(String subject) => _chapters
      .where((c) {
        final subjectRecord =
            _subjects.where((s) => s.name == subject).firstOrNull;
        return subjectRecord != null && c.subjectId == subjectRecord.id;
      })
      .map((c) => c.title)
      .toList();

  static VideoContent? getVideoById(String id) {
    for (final video in _videos) {
      if (video.id == id) return video;
    }
    return null;
  }

  static VideoContent? getVideoForLesson(String lessonId) {
    final lesson = findById(lessonId);
    if (lesson?.videoId != null && lesson!.videoId!.isNotEmpty) {
      return getVideoById(lesson.videoId!);
    }
    for (final video in _videos) {
      if (video.linkedLessonId == lessonId) return video;
    }
    return null;
  }

  static List<VideoContent> getVideosForSubject(String subject) =>
      _videos.where((v) => v.subject == subject).toList();

  static List<VideoContent> getAllVideos() => List.unmodifiable(_videos);

  static List<SubjectData> getSubjects() {
    return _subjects.map((subject) {
      final subjectLessons =
          _lessons.where((l) => l.subject == subject.name).toList();
      final subjectVideos =
          _videos.where((v) => v.subject == subject.name).toList();
      final chapterTitles = _chapters
          .where((c) => c.subjectId == subject.id)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      return SubjectData(
        id: subject.id,
        name: subject.name,
        icon: SubjectIconRegistry.iconFor(subject.iconKey),
        color: SubjectIconRegistry.colorFromHex(subject.color),
        chapters: chapterTitles.map((c) => c.title).toList(),
        lessonCount: subjectLessons.length,
        videoCount: subjectVideos.length,
      );
    }).toList();
  }
}

class _SubjectRecord {
  final String id;
  final String name;
  final String iconKey;
  final String color;

  const _SubjectRecord({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.color,
  });

  factory _SubjectRecord.fromJson(Map<String, dynamic> json) {
    return _SubjectRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: json['iconKey'] as String,
      color: json['color'] as String,
    );
  }
}

class _ChapterRecord {
  final String id;
  final String subjectId;
  final String title;
  final int order;

  const _ChapterRecord({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.order,
  });

  factory _ChapterRecord.fromJson(Map<String, dynamic> json) {
    return _ChapterRecord(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      order: json['order'] as int? ?? 0,
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
