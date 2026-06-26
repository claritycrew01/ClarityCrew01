import 'dart:convert';

class VideoContent {
  final String id;
  final String title;
  final String description;
  final String duration;
  final int durationSeconds;
  final String subject;
  final String chapter;
  final List<String> keyPoints;
  final List<String> chapters;
  final String difficulty;
  final String assetPath;
  final String linkedLessonId;
  final String? sourceId;
  final String? sourceSystem;

  const VideoContent({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    this.durationSeconds = 0,
    required this.subject,
    required this.chapter,
    required this.keyPoints,
    required this.chapters,
    this.difficulty = 'beginner',
    required this.assetPath,
    this.linkedLessonId = '',
    this.sourceId,
    this.sourceSystem,
  });

  VideoContent copyWith({
    String? id,
    String? title,
    String? description,
    String? duration,
    int? durationSeconds,
    String? subject,
    String? chapter,
    List<String>? keyPoints,
    List<String>? chapters,
    String? difficulty,
    String? assetPath,
    String? linkedLessonId,
    String? sourceId,
    String? sourceSystem,
  }) {
    return VideoContent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      keyPoints: keyPoints ?? this.keyPoints,
      chapters: chapters ?? this.chapters,
      difficulty: difficulty ?? this.difficulty,
      assetPath: assetPath ?? this.assetPath,
      linkedLessonId: linkedLessonId ?? this.linkedLessonId,
      sourceId: sourceId ?? this.sourceId,
      sourceSystem: sourceSystem ?? this.sourceSystem,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'duration': duration,
        'durationSeconds': durationSeconds,
        'subject': subject,
        'chapter': chapter,
        'keyPoints': keyPoints,
        'chapters': chapters,
        'difficulty': difficulty,
        'assetPath': assetPath,
        'linkedLessonId': linkedLessonId,
        if (sourceId != null) 'sourceId': sourceId,
        if (sourceSystem != null) 'sourceSystem': sourceSystem,
      };

  factory VideoContent.fromJson(Map<String, dynamic> json) {
    return VideoContent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      subject: json['subject'] as String? ?? '',
      chapter: json['chapter'] as String? ?? '',
      keyPoints:
          (json['keyPoints'] as List<dynamic>?)?.cast<String>() ?? const [],
      chapters:
          (json['chapters'] as List<dynamic>?)?.cast<String>() ?? const [],
      difficulty: json['difficulty'] as String? ?? 'beginner',
      assetPath: json['assetPath'] as String? ?? '',
      linkedLessonId: json['linkedLessonId'] as String? ?? '',
      sourceId: json['sourceId'] as String?,
      sourceSystem: json['sourceSystem'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory VideoContent.fromJsonString(String source) =>
      VideoContent.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
