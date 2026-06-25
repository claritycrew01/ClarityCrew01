import 'dart:convert';

enum LearningMode {
  quiz,
  video,
  flashcard,
  guidedPractice,
  microLesson,
  visualSummary,
  focusSprint,
}

enum InteractionType {
  completed,
  skipped,
  struggled,
  replayed,
  lingered,
  tappedHint,
  requestedSimpler,
  requestedDeeper,
  gaveFeedback,
  timedOut,
}

enum FeedbackStyle {
  encouraging,
  direct,
  playful,
  calm,
  detailed,
}

enum PacingPreference {
  slow,
  moderate,
  fast,
}

class LearnerProfile {
  final String id;
  final String name;
  final bool isNewUser;
  final List<String> neurodivergentTraits;
  final Map<LearningMode, double> modeWeights;
  final FeedbackStyle preferredFeedback;
  final PacingPreference pacing;
  final double depthPreference;
  final double focusThreshold;
  final bool prefersReducedMotion;
  final bool prefersReducedVisuals;
  final double fontSizeMultiplier;
  final Map<String, double> engagementHistory;
  final DateTime createdAt;
  final DateTime lastUpdated;

  const LearnerProfile({
    required this.id,
    this.name = '',
    this.isNewUser = true,
    this.neurodivergentTraits = const [],
    this.modeWeights = const {},
    this.preferredFeedback = FeedbackStyle.encouraging,
    this.pacing = PacingPreference.moderate,
    this.depthPreference = 0.5,
    this.focusThreshold = 0.6,
    this.prefersReducedMotion = false,
    this.prefersReducedVisuals = false,
    this.fontSizeMultiplier = 1.0,
    this.engagementHistory = const {},
    DateTime? createdAt,
    DateTime? lastUpdated,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  LearnerProfile copyWith({
    String? id,
    String? name,
    bool? isNewUser,
    List<String>? neurodivergentTraits,
    Map<LearningMode, double>? modeWeights,
    FeedbackStyle? preferredFeedback,
    PacingPreference? pacing,
    double? depthPreference,
    double? focusThreshold,
    bool? prefersReducedMotion,
    bool? prefersReducedVisuals,
    double? fontSizeMultiplier,
    Map<String, double>? engagementHistory,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return LearnerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      isNewUser: isNewUser ?? this.isNewUser,
      neurodivergentTraits: neurodivergentTraits ?? this.neurodivergentTraits,
      modeWeights: modeWeights ?? this.modeWeights,
      preferredFeedback: preferredFeedback ?? this.preferredFeedback,
      pacing: pacing ?? this.pacing,
      depthPreference: depthPreference ?? this.depthPreference,
      focusThreshold: focusThreshold ?? this.focusThreshold,
      prefersReducedMotion: prefersReducedMotion ?? this.prefersReducedMotion,
      prefersReducedVisuals: prefersReducedVisuals ?? this.prefersReducedVisuals,
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      engagementHistory: engagementHistory ?? this.engagementHistory,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isNewUser': isNewUser,
        'neurodivergentTraits': neurodivergentTraits,
        'modeWeights': modeWeights.map((k, v) => MapEntry(k.name, v)),
        'preferredFeedback': preferredFeedback.name,
        'pacing': pacing.name,
        'depthPreference': depthPreference,
        'focusThreshold': focusThreshold,
        'prefersReducedMotion': prefersReducedMotion,
        'prefersReducedVisuals': prefersReducedVisuals,
        'fontSizeMultiplier': fontSizeMultiplier,
        'engagementHistory': engagementHistory,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    return LearnerProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      isNewUser: json['isNewUser'] as bool? ?? true,
      neurodivergentTraits: (json['neurodivergentTraits'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      modeWeights: (json['modeWeights'] as Map<String, dynamic>?)
              ?.map((k, v) =>
                  MapEntry(LearningMode.values.byName(k), (v as num).toDouble())) ??
          {},
      preferredFeedback: FeedbackStyle.values.byName(
        json['preferredFeedback'] as String? ?? 'encouraging',
      ),
      pacing: PacingPreference.values.byName(
        json['pacing'] as String? ?? 'moderate',
      ),
      depthPreference: (json['depthPreference'] as num?)?.toDouble() ?? 0.5,
      focusThreshold: (json['focusThreshold'] as num?)?.toDouble() ?? 0.6,
      prefersReducedMotion: json['prefersReducedMotion'] as bool? ?? false,
      prefersReducedVisuals: json['prefersReducedVisuals'] as bool? ?? false,
      fontSizeMultiplier: (json['fontSizeMultiplier'] as num?)?.toDouble() ?? 1.0,
      engagementHistory: (json['engagementHistory'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory LearnerProfile.fromJsonString(String source) =>
      LearnerProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
