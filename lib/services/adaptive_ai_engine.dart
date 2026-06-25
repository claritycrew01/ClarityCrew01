import 'dart:math';
import '../models/learner_profile.dart';
import '../models/interaction_event.dart';

class AdaptiveAIEngine {
  static const double _learningRate = 0.15;
  static const double _decayFactor = 0.95;
  static const double _noveltyBonus = 0.1;

  LearnerProfile updateFromInteraction(
    LearnerProfile profile,
    InteractionEvent event,
  ) {
    final updatedWeights = _updateModeWeights(profile, event);
    final updatedFeedback = _updateFeedbackPreference(profile, event);
    final updatedPacing = _updatePacingPreference(profile, event);
    final updatedDepth = _updateDepthPreference(profile, event);
    final updatedEngagement = _updateEngagementHistory(profile, event);

    return profile.copyWith(
      modeWeights: updatedWeights,
      preferredFeedback: updatedFeedback,
      pacing: updatedPacing,
      depthPreference: updatedDepth,
      engagementHistory: updatedEngagement,
      lastUpdated: DateTime.now(),
    );
  }

  Map<LearningMode, double> _updateModeWeights(
    LearnerProfile profile,
    InteractionEvent event,
  ) {
    final mode = _inferModeFromContent(event.contentType);
    final weights = Map<LearningMode, double>.from(profile.modeWeights);

    for (final m in LearningMode.values) {
      if (!weights.containsKey(m)) {
        weights[m] = 0.5;
      }
    }

    final currentWeight = weights[mode] ?? 0.5;
    final outcomeSignal = _computeOutcomeSignal(event);
    final delta = _learningRate * (outcomeSignal - currentWeight);
    final newWeight = (currentWeight + delta).clamp(0.1, 1.0);
    weights[mode] = newWeight;

    for (final m in LearningMode.values) {
      if (m != mode) {
        weights[m] = (weights[m]! * _decayFactor).clamp(0.1, 1.0);
      }
    }

    _applyNoveltyBoost(weights, profile);
    return weights;
  }

  double _computeOutcomeSignal(InteractionEvent event) {
    double signal = 0.5;
    if (event.wasSuccessful) signal += 0.3;
    if (event.score != null) signal += (event.score! / 100) * 0.2;
    if (event.durationSeconds > 60) signal += 0.1;
    if (event.interactionType == 'completed') signal += 0.2;
    if (event.interactionType == 'struggled') signal -= 0.2;
    if (event.interactionType == 'skipped') signal -= 0.3;
    if (event.interactionType == 'replayed') signal += 0.15;
    if (event.interactionType == 'lingered') signal += 0.1;
    if (event.interactionType == 'requestedSimpler') signal -= 0.15;
    if (event.interactionType == 'requestedDeeper') signal += 0.1;
    return signal.clamp(0.0, 1.0);
  }

  FeedbackStyle _updateFeedbackPreference(
    LearnerProfile profile,
    InteractionEvent event,
  ) {
    final scores = <FeedbackStyle, double>{};
    for (final style in FeedbackStyle.values) {
      scores[style] = _computeFeedbackScore(style, profile, event);
    }
    return scores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  double _computeFeedbackScore(
    FeedbackStyle style,
    LearnerProfile profile,
    InteractionEvent event,
  ) {
    double score = style == profile.preferredFeedback ? 0.6 : 0.3;
    if (event.wasSuccessful) score += 0.2;
    if (profile.neurodivergentTraits.contains('adhd') &&
        style == FeedbackStyle.encouraging) {
      score += 0.15;
    }
    if (profile.neurodivergentTraits.contains('autism') &&
        style == FeedbackStyle.direct) {
      score += 0.15;
    }
    if (profile.neurodivergentTraits.contains('dyslexia') &&
        style == FeedbackStyle.calm) {
      score += 0.15;
    }
    return score;
  }

  PacingPreference _updatePacingPreference(
    LearnerProfile profile,
    InteractionEvent event,
  ) {
    if (event.interactionType == 'timedOut') {
      final current = PacingPreference.values.indexOf(profile.pacing);
      if (current > 0) {
        return PacingPreference.values[current - 1];
      }
    }
    if (event.interactionType == 'requestedDeeper' &&
        profile.pacing != PacingPreference.fast) {
      final current = PacingPreference.values.indexOf(profile.pacing);
      return PacingPreference.values[current + 1];
    }
    if (event.interactionType == 'requestedSimpler' &&
        profile.pacing != PacingPreference.slow) {
      final current = PacingPreference.values.indexOf(profile.pacing);
      return PacingPreference.values[current - 1];
    }
    return profile.pacing;
  }

  double _updateDepthPreference(
    LearnerProfile profile,
    InteractionEvent event,
  ) {
    double depth = profile.depthPreference;
    if (event.wasSuccessful && event.interactionType == 'completed') {
      depth += 0.05;
    }
    if (event.interactionType == 'struggled') {
      depth -= 0.05;
    }
    if (event.interactionType == 'requestedDeeper') {
      depth += 0.1;
    }
    if (event.interactionType == 'requestedSimpler') {
      depth -= 0.1;
    }
    return depth.clamp(0.1, 1.0);
  }

  Map<String, double> _updateEngagementHistory(
    LearnerProfile profile,
    InteractionEvent event,
  ) {
    final history = Map<String, double>.from(profile.engagementHistory);
    final key = '${event.contentType}_${event.interactionType}';
    final current = history[key] ?? 0.0;
    history[key] = (current + _computeOutcomeSignal(event) * 0.3).clamp(0.0, 1.0);
    return history;
  }

  void _applyNoveltyBoost(
    Map<LearningMode, double> weights,
    LearnerProfile profile,
  ) {
    if (profile.engagementHistory.isEmpty) return;
    final leastUsed = weights.entries
        .where((e) => e.value < 0.4)
        .map((e) => e.key)
        .toList();
    if (leastUsed.isNotEmpty) {
      final random = Random();
      final boostTarget = leastUsed[random.nextInt(leastUsed.length)];
      weights[boostTarget] =
          (weights[boostTarget]! + _noveltyBonus).clamp(0.1, 1.0);
    }
  }

  LearningMode _inferModeFromContent(String contentType) {
    switch (contentType) {
      case 'quiz':
        return LearningMode.quiz;
      case 'video':
        return LearningMode.video;
      case 'flashcard':
        return LearningMode.flashcard;
      case 'guided_practice':
        return LearningMode.guidedPractice;
      case 'micro_lesson':
        return LearningMode.microLesson;
      case 'visual_summary':
        return LearningMode.visualSummary;
      case 'focus_sprint':
        return LearningMode.focusSprint;
      default:
        return LearningMode.microLesson;
    }
  }

  double predictEngagement(
    LearnerProfile profile,
    LearningMode mode,
  ) {
    final modeWeight = profile.modeWeights[mode] ?? 0.5;
    final pacingFactor = _pacingFactor(profile.pacing);
    final engagementTrend = _averageEngagement(profile);
    return (modeWeight * 0.5 + pacingFactor * 0.3 + engagementTrend * 0.2)
        .clamp(0.0, 1.0);
  }

  double _pacingFactor(PacingPreference pacing) {
    switch (pacing) {
      case PacingPreference.slow:
        return 0.7;
      case PacingPreference.moderate:
        return 0.5;
      case PacingPreference.fast:
        return 0.3;
    }
  }

  double _averageEngagement(LearnerProfile profile) {
    final values = profile.engagementHistory.values.toList();
    if (values.isEmpty) return 0.5;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
