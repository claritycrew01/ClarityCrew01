import 'dart:convert';
import 'interaction_event.dart';

class SessionRecord {
  final String id;
  final String learnerId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final List<InteractionEvent> interactions;
  final double engagementScore;
  final double comprehensionScore;
  final String sessionType;
  final List<String> topicTags;
  final bool completed;

  const SessionRecord({
    required this.id,
    required this.learnerId,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.interactions = const [],
    this.engagementScore = 0.0,
    this.comprehensionScore = 0.0,
    this.sessionType = 'general',
    this.topicTags = const [],
    this.completed = false,
  });

  SessionRecord copyWith({
    String? id,
    String? learnerId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    List<InteractionEvent>? interactions,
    double? engagementScore,
    double? comprehensionScore,
    String? sessionType,
    List<String>? topicTags,
    bool? completed,
  }) {
    return SessionRecord(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      interactions: interactions ?? this.interactions,
      engagementScore: engagementScore ?? this.engagementScore,
      comprehensionScore: comprehensionScore ?? this.comprehensionScore,
      sessionType: sessionType ?? this.sessionType,
      topicTags: topicTags ?? this.topicTags,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'learnerId': learnerId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationSeconds': durationSeconds,
        'interactions': interactions.map((e) => e.toJson()).toList(),
        'engagementScore': engagementScore,
        'comprehensionScore': comprehensionScore,
        'sessionType': sessionType,
        'topicTags': topicTags,
        'completed': completed,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'] as String,
      learnerId: json['learnerId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      interactions: (json['interactions'] as List<dynamic>?)
              ?.map((e) =>
                  InteractionEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      engagementScore: (json['engagementScore'] as num?)?.toDouble() ?? 0.0,
      comprehensionScore:
          (json['comprehensionScore'] as num?)?.toDouble() ?? 0.0,
      sessionType: json['sessionType'] as String? ?? 'general',
      topicTags:
          (json['topicTags'] as List<dynamic>?)?.cast<String>() ?? [],
      completed: json['completed'] as bool? ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SessionRecord.fromJsonString(String source) =>
      SessionRecord.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
