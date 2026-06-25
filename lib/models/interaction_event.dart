import 'dart:convert';

class InteractionEvent {
  final String id;
  final String sessionId;
  final String learnerId;
  final String contentType;
  final String contentId;
  final String interactionType;
  final double durationSeconds;
  final bool wasSuccessful;
  final int? score;
  final String? feedback;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const InteractionEvent({
    required this.id,
    required this.sessionId,
    required this.learnerId,
    required this.contentType,
    required this.contentId,
    required this.interactionType,
    this.durationSeconds = 0,
    this.wasSuccessful = true,
    this.score,
    this.feedback,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'learnerId': learnerId,
        'contentType': contentType,
        'contentId': contentId,
        'interactionType': interactionType,
        'durationSeconds': durationSeconds,
        'wasSuccessful': wasSuccessful,
        'score': score,
        'feedback': feedback,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };

  factory InteractionEvent.fromJson(Map<String, dynamic> json) {
    return InteractionEvent(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      learnerId: json['learnerId'] as String,
      contentType: json['contentType'] as String,
      contentId: json['contentId'] as String,
      interactionType: json['interactionType'] as String,
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0,
      wasSuccessful: json['wasSuccessful'] as bool? ?? true,
      score: json['score'] as int?,
      feedback: json['feedback'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory InteractionEvent.fromJsonString(String source) =>
      InteractionEvent.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
