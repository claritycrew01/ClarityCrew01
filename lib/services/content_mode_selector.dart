import 'dart:math';
import '../models/learner_profile.dart';

class ContentModeSelector {
  final Random _random = Random();

  LearningMode selectNextMode(LearnerProfile profile) {
    final weights = profile.modeWeights;
    if (weights.isEmpty) {
      return _randomInitialMode();
    }

    final totalWeight = weights.values.fold(0.0, (a, b) => a + b);
    if (totalWeight <= 0) {
      return _randomInitialMode();
    }

    double roll = _random.nextDouble() * totalWeight;
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) {
        return entry.key;
      }
    }

    return weights.entries.last.key;
  }

  LearningMode selectNextModeWithFallback(
    LearnerProfile profile,
    LearningMode preferred,
  ) {
    final predicted = predictBestMode(profile);
    if (predicted == preferred) return preferred;

    if (_random.nextDouble() < 0.7) {
      return predicted;
    }
    return preferred;
  }

  LearningMode predictBestMode(LearnerProfile profile) {
    return profile.modeWeights.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  double getModeConfidence(LearnerProfile profile, LearningMode mode) {
    return profile.modeWeights[mode] ?? 0.5;
  }

  LearningMode _randomInitialMode() {
    final modes = LearningMode.values;
    return modes[_random.nextInt(modes.length)];
  }
}
