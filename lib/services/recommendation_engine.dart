import 'dart:math';
import '../models/learner_profile.dart';
import '../models/learning_recommendation.dart';
import '../models/session_record.dart';
import '../models/content_item.dart';
import 'adaptive_ai_engine.dart';
import 'content_mode_selector.dart';

class RecommendationEngine {
  final AdaptiveAIEngine _aiEngine = AdaptiveAIEngine();
  final ContentModeSelector _modeSelector = ContentModeSelector();
  final Random _random = Random();
  int _recommendationCounter = 0;

  LearningRecommendation generateRecommendation(
    LearnerProfile profile,
    List<SessionRecord> recentSessions,
  ) {
    _recommendationCounter++;
    final bestMode = _modeSelector.selectNextMode(profile);
    final confidence = _modeSelector.getModeConfidence(profile, bestMode);
    final predictedEngagement = _aiEngine.predictEngagement(profile, bestMode);

    final reason = _generateReason(profile, bestMode, predictedEngagement);
    final title = _generateTitle(bestMode, profile);
    final description = _generateDescription(bestMode, confidence);
    final difficulty = _selectDifficulty(profile);
    final duration = _estimateDuration(bestMode, profile.pacing);

    return LearningRecommendation(
      id: 'rec_$_recommendationCounter',
      learnerId: profile.id,
      recommendedMode: bestMode,
      title: title,
      description: description,
      confidence: confidence,
      reason: reason,
      estimatedDuration: duration,
      difficulty: difficulty,
      isUrgent: predictedEngagement < 0.3,
    );
  }

  List<LearningRecommendation> generateMultipleRecommendations(
    LearnerProfile profile,
    List<SessionRecord> recentSessions, {
    int count = 3,
  }) {
    final recommendations = <LearningRecommendation>[];
    final usedModes = <LearningMode>{};

    for (int i = 0; i < count; i++) {
      final rec = generateRecommendation(profile, recentSessions);
      if (!usedModes.contains(rec.recommendedMode)) {
        recommendations.add(rec);
        usedModes.add(rec.recommendedMode);
      } else {
        final remaining = LearningMode.values
            .where((m) => !usedModes.contains(m))
            .toList();
        if (remaining.isNotEmpty) {
          final altMode = remaining[_random.nextInt(remaining.length)];
          recommendations.add(LearningRecommendation(
            id: 'rec_${_recommendationCounter}_alt',
            learnerId: profile.id,
            recommendedMode: altMode,
            title: _generateTitle(altMode, profile),
            description: _generateDescription(
              altMode,
              _modeSelector.getModeConfidence(profile, altMode),
            ),
            confidence: _modeSelector.getModeConfidence(profile, altMode),
            reason: 'Try a different approach to keep things fresh',
            estimatedDuration: _estimateDuration(altMode, profile.pacing),
            difficulty: _selectDifficulty(profile),
          ));
        }
      }
    }

    return recommendations;
  }

  String _generateReason(
    LearnerProfile profile,
    LearningMode mode,
    double engagement,
  ) {
    if (engagement < 0.3) {
      return 'Let us try something different to re-engage your focus';
    }
    if (engagement > 0.7) {
      return 'You have been doing great with this format';
    }
    return 'This format seems to match your current energy well';
  }

  String _generateTitle(LearningMode mode, LearnerProfile profile) {
    switch (mode) {
      case LearningMode.quiz:
        return 'Quick Challenge';
      case LearningMode.video:
        return 'Watch & Learn';
      case LearningMode.flashcard:
        return 'Memory Boost';
      case LearningMode.guidedPractice:
        return 'Guided Practice';
      case LearningMode.microLesson:
        return 'Bite-Sized Lesson';
      case LearningMode.visualSummary:
        return 'Visual Overview';
      case LearningMode.focusSprint:
        return 'Focus Sprint';
    }
  }

  String _generateDescription(LearningMode mode, double confidence) {
    final base = _baseDescription(mode);
    if (confidence > 0.7) {
      return '$base — a great fit for how you learn best';
    } else if (confidence > 0.4) {
      return '$base — a solid option for today';
    } else {
      return '$base — something new to try';
    }
  }

  String _baseDescription(LearningMode mode) {
    switch (mode) {
      case LearningMode.quiz:
        return 'Test your knowledge with interactive questions';
      case LearningMode.video:
        return 'Watch a short animated explanation';
      case LearningMode.flashcard:
        return 'Review key concepts with quick cards';
      case LearningMode.guidedPractice:
        return 'Step-by-step practice with feedback';
      case LearningMode.microLesson:
        return 'A quick focused lesson in 5 minutes';
      case LearningMode.visualSummary:
        return 'See the big picture with a visual map';
      case LearningMode.focusSprint:
        return 'A timed focus session to dive deep';
    }
  }

  String _selectDifficulty(LearnerProfile profile) {
    final depth = profile.depthPreference;
    if (depth < 0.3) return 'beginner';
    if (depth < 0.6) return 'intermediate';
    return 'advanced';
  }

  int _estimateDuration(LearningMode mode, PacingPreference pacing) {
    final base = _baseDuration(mode);
    switch (pacing) {
      case PacingPreference.slow:
        return (base * 1.5).round();
      case PacingPreference.moderate:
        return base;
      case PacingPreference.fast:
        return (base * 0.7).round();
    }
  }

  int _baseDuration(LearningMode mode) {
    switch (mode) {
      case LearningMode.quiz:
        return 180;
      case LearningMode.video:
        return 240;
      case LearningMode.flashcard:
        return 120;
      case LearningMode.guidedPractice:
        return 300;
      case LearningMode.microLesson:
        return 300;
      case LearningMode.visualSummary:
        return 180;
      case LearningMode.focusSprint:
        return 1500;
    }
  }
}
