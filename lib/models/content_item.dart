import 'dart:convert';

class ContentItem {
  final String id;
  final String title;
  final String description;
  final String contentType;
  final String difficulty;
  final int estimatedDurationSeconds;
  final List<String> tags;
  final String body;
  final Map<String, String> metadata;
  final List<String> quizOptions;
  final int? correctOptionIndex;
  final List<ContentItem> flashcards;

  const ContentItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.contentType,
    this.difficulty = 'beginner',
    this.estimatedDurationSeconds = 300,
    this.tags = const [],
    this.body = '',
    this.metadata = const {},
    this.quizOptions = const [],
    this.correctOptionIndex,
    this.flashcards = const [],
  });

  ContentItem copyWith({
    String? id,
    String? title,
    String? description,
    String? contentType,
    String? difficulty,
    int? estimatedDurationSeconds,
    List<String>? tags,
    String? body,
    Map<String, String>? metadata,
    List<String>? quizOptions,
    int? correctOptionIndex,
    List<ContentItem>? flashcards,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      contentType: contentType ?? this.contentType,
      difficulty: difficulty ?? this.difficulty,
      estimatedDurationSeconds:
          estimatedDurationSeconds ?? this.estimatedDurationSeconds,
      tags: tags ?? this.tags,
      body: body ?? this.body,
      metadata: metadata ?? this.metadata,
      quizOptions: quizOptions ?? this.quizOptions,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      flashcards: flashcards ?? this.flashcards,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'contentType': contentType,
        'difficulty': difficulty,
        'estimatedDurationSeconds': estimatedDurationSeconds,
        'tags': tags,
        'body': body,
        'metadata': metadata,
        'quizOptions': quizOptions,
        'correctOptionIndex': correctOptionIndex,
        'flashcards': flashcards.map((f) => f.toJson()).toList(),
      };

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      contentType: json['contentType'] as String,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      estimatedDurationSeconds:
          json['estimatedDurationSeconds'] as int? ?? 300,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      body: json['body'] as String? ?? '',
      metadata: (json['metadata'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      quizOptions:
          (json['quizOptions'] as List<dynamic>?)?.cast<String>() ?? [],
      correctOptionIndex: json['correctOptionIndex'] as int?,
      flashcards: (json['flashcards'] as List<dynamic>?)
              ?.map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ContentItem.fromJsonString(String source) =>
      ContentItem.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
