import 'package:flutter/material.dart';

import '../models/content_item.dart';
import '../models/learner_profile.dart';
import '../models/learning_recommendation.dart';
import '../services/content/content_repository.dart';
import '../features/flashcards/flashcard_screen.dart';
import '../features/focus/focus_mode_screen.dart';
import '../features/learning/learning_session_screen.dart';
import '../features/quiz/quiz_screen.dart';
import '../features/video/video_screen.dart';

class StudyNavigation {
  StudyNavigation._();

  static ContentItem? contentForRecommendation(LearningRecommendation rec) {
    if (rec.contentId == null) return null;
    if (rec.recommendedMode == LearningMode.video) {
      final video = ContentRepository.getVideoById(rec.contentId!);
      if (video != null && video.linkedLessonId.isNotEmpty) {
        return ContentRepository.findById(video.linkedLessonId);
      }
    }
    return ContentRepository.findById(rec.contentId!);
  }

  static void launchMode(
    BuildContext context,
    LearningMode mode, {
    String? contentId,
  }) {
    switch (mode) {
      case LearningMode.quiz:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuizScreen(initialLessonId: contentId)),
        );
      case LearningMode.video:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoScreen(
              videoId: _resolveVideoId(contentId),
              lessonId: _resolveLessonId(contentId),
            ),
          ),
        );
      case LearningMode.flashcard:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlashcardScreen(initialLessonId: contentId),
          ),
        );
      case LearningMode.guidedPractice:
      case LearningMode.microLesson:
      case LearningMode.visualSummary:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LearningSessionScreen(initialLessonId: contentId),
          ),
        );
      case LearningMode.focusSprint:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FocusModeScreen()),
        );
    }
  }

  static void launchRecommendation(
    BuildContext context,
    LearningRecommendation rec,
  ) {
    launchMode(
      context,
      rec.recommendedMode,
      contentId: rec.contentId,
    );
  }

  static String? _resolveVideoId(String? contentId) {
    if (contentId == null) return null;
    final video = ContentRepository.getVideoById(contentId);
    if (video != null) return video.id;
    final lesson = ContentRepository.findById(contentId);
    return lesson?.videoId;
  }

  static String? _resolveLessonId(String? contentId) {
    if (contentId == null) return null;
    final lesson = ContentRepository.findById(contentId);
    if (lesson != null) return lesson.id;
    final video = ContentRepository.getVideoById(contentId);
    return video?.linkedLessonId;
  }
}
