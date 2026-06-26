import '../../models/content_item.dart';
import '../../models/subject_data.dart';
import '../../models/video_content.dart';
import 'firestore_content_service.dart';
import 'subject_icon_registry.dart';

class ContentRepository {
  ContentRepository._();
  static final ContentRepository instance = ContentRepository._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    final service = FirestoreContentService.instance;
    await service.initialize();

    _initialized = true;
  }

  static bool get usingRemote => FirestoreContentService.instance.usingRemote;

  static List<ContentItem> getAll() =>
      FirestoreContentService.instance.allLessons;

  static ContentItem getById(String id) {
    final lessons = FirestoreContentService.instance.allLessons;
    return lessons.firstWhere(
      (l) => l.id == id,
      orElse: () => lessons.first,
    );
  }

  static ContentItem? findById(String id) {
    for (final lesson in FirestoreContentService.instance.allLessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  static List<ContentItem> getByTags(List<String> tags) {
    final lessons = FirestoreContentService.instance.allLessons;
    return lessons
        .where((l) => l.tags.any((t) => tags.contains(t)))
        .toList();
  }

  static List<ContentItem> getByDifficulty(String difficulty) {
    final lessons = FirestoreContentService.instance.allLessons;
    return lessons.where((l) => l.difficulty == difficulty).toList();
  }

  static List<ContentItem> getByType(String contentType) {
    final lessons = FirestoreContentService.instance.allLessons;
    if (contentType == 'lesson') {
      return lessons
          .where((l) =>
              l.contentType != 'quiz' &&
              l.contentType != 'flashcard' &&
              l.contentType != 'video')
          .toList();
    }
    return lessons.where((l) => l.contentType == contentType).toList();
  }

  static List<ContentItem> getBySubject(String subject) {
    final lessons = FirestoreContentService.instance.allLessons;
    return lessons.where((l) => l.subject == subject).toList();
  }

  static List<String> getAllSubjectNames() {
    final lessons = FirestoreContentService.instance.allLessons;
    return lessons.map((l) => l.subject).toSet().toList()..sort();
  }

  static List<String> getChaptersForSubject(String subject) {
    final chapters = FirestoreContentService.instance.allChapters;
    final subjects = FirestoreContentService.instance.allSubjects;
    return chapters
        .where((c) {
          final subjectRecord =
              subjects.where((s) => s.name == subject).firstOrNull;
          return subjectRecord != null && c.subjectId == subjectRecord.id;
        })
        .map((c) => c.title)
        .toList();
  }

  static VideoContent? getVideoById(String id) {
    for (final video in FirestoreContentService.instance.allVideos) {
      if (video.id == id) return video;
    }
    return null;
  }

  static VideoContent? getVideoForLesson(String lessonId) {
    final lesson = findById(lessonId);
    if (lesson?.videoId != null && lesson!.videoId!.isNotEmpty) {
      return getVideoById(lesson.videoId!);
    }
    for (final video in FirestoreContentService.instance.allVideos) {
      if (video.linkedLessonId == lessonId) return video;
    }
    return null;
  }

  static List<VideoContent> getVideosForSubject(String subject) {
    final videos = FirestoreContentService.instance.allVideos;
    return videos.where((v) => v.subject == subject).toList();
  }

  static List<VideoContent> getAllVideos() =>
      FirestoreContentService.instance.allVideos;

  static List<SubjectData> getSubjects() {
    final subjects = FirestoreContentService.instance.allSubjects;
    final lessons = FirestoreContentService.instance.allLessons;
    final videos = FirestoreContentService.instance.allVideos;
    final chapters = FirestoreContentService.instance.allChapters;

    return subjects.map((subject) {
      final subjectLessons =
          lessons.where((l) => l.subject == subject.name).toList();
      final subjectVideos =
          videos.where((v) => v.subject == subject.name).toList();
      final chapterTitles = chapters
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

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
