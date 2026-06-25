import 'dart:convert';
import 'learner_profile.dart';

class LearningRecommendation {
  final String id;
  final String learnerId;
  final LearningMode recommendedMode;
  final String title;
  final String description;
  final double confidence;
  final String reason;
  final int estimatedDuration;
  final String difficulty;
  final bool isUrgent;
  final DateTime generatedAt;

  LearningRecommendation({
    required this.id,
    required this.learnerId,
    required this.recommendedMode,
    required this.title,
    this.description = '',
    this.confidence = 0.5,
    this.reason = '',
    this.estimatedDuration = 300,
    this.difficulty = 'beginner',
    this.isUrgent = false,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'learnerId': learnerId,
        'recommendedMode': recommendedMode.name,
        'title': title,
        'description': description,
        'confidence': confidence,
        'reason': reason,
        'estimatedDuration': estimatedDuration,
        'difficulty': difficulty,
        'isUrgent': isUrgent,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory LearningRecommendation.fromJson(Map<String, dynamic> json) {
    return LearningRecommendation(
      id: json['id'] as String,
      learnerId: json['learnerId'] as String,
      recommendedMode:
          LearningMode.values.byName(json['recommendedMode'] as String),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      reason: json['reason'] as String? ?? '',
      estimatedDuration: json['estimatedDuration'] as int? ?? 300,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      isUrgent: json['isUrgent'] as bool? ?? false,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory LearningRecommendation.fromJsonString(String source) =>
      LearningRecommendation.fromJson(
          jsonDecode(source) as Map<String, dynamic>);
}
