import 'dart:math';
import '../models/learner_profile.dart';
import '../models/learning_recommendation.dart';
import '../models/session_record.dart';
import '../models/content_item.dart';
import 'adaptive_ai_engine.dart';
import 'content_mode_selector.dart';
import 'content/content_repository.dart';

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
    final content = _selectContent(bestMode, profile);
    final contentId = _contentIdForMode(bestMode, content);

    final reason = _generateReason(profile, bestMode, predictedEngagement, content);
    final title = _generateTitle(bestMode, profile, content);
    final description = _generateDescription(bestMode, confidence, content);
    final difficulty = _selectDifficulty(profile);
    final duration = _estimateDuration(bestMode, profile.pacing, content);

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
      contentId: contentId,
    );
  }

  List<LearningRecommendation> generateMultipleRecommendations(
    LearnerProfile profile,
    List<SessionRecord> recentSessions, {
    int count = 3,
  }) {
    final recommendations = <LearningRecommendation>[];
    final usedModes = <LearningMode>{};
    final usedContent = <String>{};

    for (int i = 0; i < count; i++) {
      final rec = generateRecommendation(profile, recentSessions);
      final contentKey = rec.contentId ?? rec.recommendedMode.name;
      if (!usedModes.contains(rec.recommendedMode) &&
          !usedContent.contains(contentKey)) {
        recommendations.add(rec);
        usedModes.add(rec.recommendedMode);
        usedContent.add(contentKey);
      } else {
        final remaining = LearningMode.values
            .where((m) => !usedModes.contains(m))
            .toList();
        if (remaining.isNotEmpty) {
          final altMode = remaining[_random.nextInt(remaining.length)];
          final content = _selectContent(altMode, profile, excludeIds: usedContent);
          final contentId = _contentIdForMode(altMode, content);
          recommendations.add(LearningRecommendation(
            id: 'rec_${_recommendationCounter}_alt',
            learnerId: profile.id,
            recommendedMode: altMode,
            title: _generateTitle(altMode, profile, content),
            description: _generateDescription(
              altMode,
              _modeSelector.getModeConfidence(profile, altMode),
              content,
            ),
            confidence: _modeSelector.getModeConfidence(profile, altMode),
            reason: 'Try a different approach to keep things fresh',
            estimatedDuration: _estimateDuration(altMode, profile.pacing, content),
            difficulty: _selectDifficulty(profile),
            contentId: contentId,
          ));
          usedModes.add(altMode);
          if (contentId != null) usedContent.add(contentId);
        }
      }
    }

    return recommendations;
  }

  ContentItem? _selectContent(
    LearningMode mode,
    LearnerProfile profile, {
    Set<String> excludeIds = const {},
  }) {
    final difficulty = _selectDifficulty(profile);
    List<ContentItem> candidates;

    switch (mode) {
      case LearningMode.quiz:
        candidates = ContentRepository.getAll()
            .where((l) => l.quizOptions.isNotEmpty)
            .toList();
      case LearningMode.video:
        candidates = ContentRepository.getAll()
            .where((l) => (l.videoId ?? '').isNotEmpty)
            .toList();
      case LearningMode.flashcard:
        candidates = ContentRepository.getAll()
            .where((l) => l.flashcards.isNotEmpty)
            .toList();
      case LearningMode.guidedPractice:
        candidates =
            ContentRepository.getByType('guided_practice');
      case LearningMode.microLesson:
        candidates = ContentRepository.getByType('micro_lesson');
      case LearningMode.visualSummary:
        candidates = ContentRepository.getByType('visual_summary');
      case LearningMode.focusSprint:
        candidates = ContentRepository.getAll();
    }

    candidates = candidates
        .where((item) => !excludeIds.contains(item.id))
        .where((item) => item.difficulty == difficulty)
        .toList();
    if (candidates.isEmpty) {
      candidates = ContentRepository.getAll()
          .where((item) => !excludeIds.contains(item.id))
          .toList();
    }
    if (candidates.isEmpty) return null;
    return candidates[_random.nextInt(candidates.length)];
  }

  String? _contentIdForMode(LearningMode mode, ContentItem? content) {
    if (content == null) return null;
    if (mode == LearningMode.video) {
      return content.videoId ?? content.id;
    }
    return content.id;
  }

  String _generateReason(
    LearnerProfile profile,
    LearningMode mode,
    double engagement,
    ContentItem? content,
  ) {
    final contentLine =
        content != null ? ' "${content.title}" fits your current level.' : '';
    if (engagement < 0.3) {
      return 'Let us try something different to re-engage your focus.$contentLine';
    }
    if (engagement > 0.7) {
      return 'You have been doing great with this format.$contentLine';
    }
    return 'This format seems to match your current energy well.$contentLine';
  }

  String _generateTitle(
    LearningMode mode,
    LearnerProfile profile,
    ContentItem? content,
  ) {
    if (content != null) {
      switch (mode) {
        case LearningMode.quiz:
          return '${content.subject} Challenge: ${content.title}';
        case LearningMode.video:
          return 'Watch: ${content.title}';
        case LearningMode.flashcard:
          return 'Review: ${content.title}';
        case LearningMode.focusSprint:
          return '${content.subject} Focus Sprint';
        default:
          return content.title;
      }
    }

    final subjects = ContentRepository.getAllSubjectNames();
    final subject =
        subjects.isNotEmpty ? subjects[_random.nextInt(subjects.length)] : null;
    final subjectPrefix = subject != null ? '$subject ' : '';

    switch (mode) {
      case LearningMode.quiz:
        return '${subjectPrefix}Challenge';
      case LearningMode.video:
        return 'Watch $subjectPrefix& Learn';
      case LearningMode.flashcard:
        return '${subjectPrefix}Memory Boost';
      case LearningMode.guidedPractice:
        return '${subjectPrefix}Guided Practice';
      case LearningMode.microLesson:
        return '${subjectPrefix}Bite-Sized Lesson';
      case LearningMode.visualSummary:
        return '${subjectPrefix}Visual Overview';
      case LearningMode.focusSprint:
        return '${subjectPrefix}Focus Sprint';
    }
  }

  String _generateDescription(
    LearningMode mode,
    double confidence,
    ContentItem? content,
  ) {
    final base = _baseDescription(mode);
    final suffix =
        content != null ? ' Focus on "${content.title}".' : '';

    if (confidence > 0.7) {
      return '$base$suffix — a great fit for how you learn best';
    } else if (confidence > 0.4) {
      return '$base$suffix — a solid option for today';
    } else {
      return '$base$suffix — something new to try';
    }
  }

  String _baseDescription(LearningMode mode) {
    switch (mode) {
      case LearningMode.quiz:
        return 'Test your knowledge with interactive questions';
      case LearningMode.video:
        return 'Watch a short offline video explanation';
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

  int _estimateDuration(
    LearningMode mode,
    PacingPreference pacing,
    ContentItem? content,
  ) {
    final base = content?.estimatedDurationSeconds ?? _baseDuration(mode);
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
