import '../../models/content_item.dart';
import '../../models/learner_profile.dart';
import '../../models/learning_recommendation.dart';
import '../../models/tutor_message.dart';
import '../../models/video_content.dart';
import '../content/content_repository.dart';

enum TutorIntent {
  explain,
  simplify,
  goDeeper,
  whyRecommendation,
  whatNext,
  general,
}

class TutorService {
  TutorMessage respond({
    required String userMessage,
    required LearnerProfile profile,
    String? contentId,
    LearningRecommendation? activeRecommendation,
  }) {
    final intent = _detectIntent(userMessage);
    final lesson =
        contentId != null ? ContentRepository.getById(contentId) : null;
    final videos = lesson != null
        ? ContentRepository.getVideosForSubject(lesson.subject)
        : <VideoContent>[];
    final video = videos.isNotEmpty ? videos.first : null;
    final text = _buildResponse(
      intent: intent,
      message: userMessage,
      profile: profile,
      lesson: lesson,
      video: video,
      recommendation: activeRecommendation,
    );

    return TutorMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'tutor',
      text: text,
      contentId: contentId ?? lesson?.id,
      timestamp: DateTime.now(),
    );
  }

  TutorIntent _detectIntent(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('simplif') || lower.contains('easier')) {
      return TutorIntent.simplify;
    }
    if (lower.contains('deeper') ||
        lower.contains('more detail') ||
        lower.contains('advanced')) {
      return TutorIntent.goDeeper;
    }
    if (lower.contains('why') &&
        (lower.contains('recommend') || lower.contains('suggest'))) {
      return TutorIntent.whyRecommendation;
    }
    if (lower.contains('what next') ||
        lower.contains('what should i') ||
        lower.contains('what now')) {
      return TutorIntent.whatNext;
    }
    if (lower.contains('explain') ||
        lower.contains('help') ||
        lower.contains('what is') ||
        lower.contains('how do')) {
      return TutorIntent.explain;
    }
    return TutorIntent.general;
  }

  String _buildResponse({
    required TutorIntent intent,
    required String message,
    required LearnerProfile profile,
    ContentItem? lesson,
    VideoContent? video,
    LearningRecommendation? recommendation,
  }) {
    switch (intent) {
      case TutorIntent.simplify:
        return _simplifyResponse(lesson, profile);
      case TutorIntent.goDeeper:
        return _deeperResponse(lesson, profile);
      case TutorIntent.whyRecommendation:
        return _whyRecommendation(recommendation, profile);
      case TutorIntent.whatNext:
        return _whatNext(profile, recommendation);
      case TutorIntent.explain:
        return _explainResponse(lesson, video, message, profile);
      case TutorIntent.general:
        return _generalResponse(lesson, profile, message);
    }
  }

  String _feedbackTone(LearnerProfile profile) {
    switch (profile.preferredFeedback) {
      case FeedbackStyle.encouraging:
        return 'You are doing well — ';
      case FeedbackStyle.direct:
        return '';
      case FeedbackStyle.playful:
        return 'Good question! ';
      case FeedbackStyle.calm:
        return 'Take your time. ';
      case FeedbackStyle.detailed:
        return 'Here is a detailed breakdown: ';
    }
  }

  String _pacingHint(LearnerProfile profile) {
    switch (profile.pacing) {
      case PacingPreference.slow:
        return 'I will keep this step-by-step.';
      case PacingPreference.moderate:
        return 'Here is a balanced explanation.';
      case PacingPreference.fast:
        return 'Here is the quick version.';
    }
  }

  String _explainResponse(
    ContentItem? lesson,
    VideoContent? video,
    String message,
    LearnerProfile profile,
  ) {
    if (lesson == null) {
      return '${_feedbackTone(profile)}Pick a lesson from Recommendations or ask me about a subject like Algebra, Biology, or English. ${_pacingHint(profile)}';
    }

    final excerpt = _firstParagraph(lesson.body);
    final videoHint = video != null
        ? ' There is also a video lesson "${video.title}" you can watch offline.'
        : '';

    return '${_feedbackTone(profile)}For "${lesson.title}": $excerpt$videoHint ${_pacingHint(profile)}';
  }

  String _simplifyResponse(ContentItem? lesson, LearnerProfile profile) {
    if (lesson == null) {
      return '${_feedbackTone(profile)}Tell me which lesson you want simplified, or tap a recommendation card first.';
    }
    final sentences = lesson.body.split(RegExp(r'(?<=[.!?])\s+'));
    final simplified = sentences.take(2).join(' ');
    final tags = lesson.tags.take(3).join(', ');
    final tagLine =
        tags.isNotEmpty ? '\n\nKey ideas: $tags.' : '';
    return '${_feedbackTone(profile)}Simplified "${lesson.title}": $simplified$tagLine';
  }

  String _deeperResponse(ContentItem? lesson, LearnerProfile profile) {
    if (lesson == null) {
      return '${_feedbackTone(profile)}Choose a lesson and I can go deeper into that topic.';
    }
    final paragraphs = lesson.body.split('\n\n');
    final detail = paragraphs.length > 1
        ? paragraphs.sublist(1).take(2).join('\n\n')
        : lesson.body;
    return '${_feedbackTone(profile)}Going deeper on "${lesson.title}": $detail';
  }

  String _whyRecommendation(
    LearningRecommendation? recommendation,
    LearnerProfile profile,
  ) {
    if (recommendation == null) {
      return '${_feedbackTone(profile)}Complete a session and I will explain why each recommendation fits your learning patterns.';
    }

    final lesson = recommendation.contentId != null
        ? ContentRepository.getById(recommendation.contentId!)
        : null;
    final lessonLine = lesson != null
        ? ' I picked "${lesson.title}" because it matches your current study flow.'
        : '';

    return '${_feedbackTone(profile)}${recommendation.reason}.$lessonLine Confidence: ${(recommendation.confidence * 100).round()}%.';
  }

  String _whatNext(
    LearnerProfile profile,
    LearningRecommendation? recommendation,
  ) {
    if (recommendation == null) {
      final mode = profile.modeWeights.entries.isEmpty
          ? 'a micro lesson'
          : profile.modeWeights.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
              .name
              .replaceAll('_', ' ');
      return '${_feedbackTone(profile)}Try $mode next to build momentum. ${_pacingHint(profile)}';
    }

    final lesson = recommendation.contentId != null
        ? ContentRepository.getById(recommendation.contentId!)
        : null;
    final target = lesson?.title ?? recommendation.title;
    return '${_feedbackTone(profile)}Next up: $target — ${recommendation.description}';
  }

  String _generalResponse(
    ContentItem? lesson,
    LearnerProfile profile,
    String message,
  ) {
    if (lesson != null) {
      final videos = ContentRepository.getVideosForSubject(lesson.subject);
      final video = videos.isNotEmpty ? videos.first : null;
      return _explainResponse(lesson, video, message, profile);
    }
    return '${_feedbackTone(profile)}I can explain lesson content, simplify ideas, go deeper, or tell you what to study next. Try asking "Explain linear equations" or "What should I study next?"';
  }

  String _firstParagraph(String body) {
    final parts = body.split('\n\n');
    final first = parts.isNotEmpty ? parts.first : body;
    if (first.length <= 220) return first;
    return '${first.substring(0, 217)}...';
  }
}
