import 'dart:math';
import '../../models/content_item.dart';
import '../../models/learner_profile.dart';
import '../../models/learning_recommendation.dart';
import '../../models/tutor_message.dart';
import '../../models/video_content.dart';
import '../content/content_repository.dart';
import 'conversation_history.dart';

/// System prompt embedded into the generator's logic.
/// The AI follows these rules:
/// - Answer directly first, then elaborate if needed.
/// - Keep replies concise unless the user asks for detail.
/// - Avoid generic filler like "That's a great question!" unless truly warranted.
/// - Say "I'm not sure" when the context is insufficient.
/// - Ask one clear follow-up question when the user's intent is ambiguous.
/// - Reference lesson content when available; avoid inventing facts.
enum ResponseDepth { brief, balanced, detailed }

class ResponseGenerator {
  final _random = Random();
  int _turnCounter = 0;

  String generate({
    required String userMessage,
    required LearnerProfile profile,
    required ConversationHistory history,
    String? contentId,
    LearningRecommendation? activeRecommendation,
  }) {
    _turnCounter++;
    final lower = userMessage.trim().toLowerCase();

    // Edge cases: empty or very short input
    if (lower.isEmpty) {
      return _pick(_emptyFallbacks);
    }
    if (lower.length < 3 && !RegExp(r'^(hi|hey|ok|yes|no|why|how)$').hasMatch(lower)) {
      return _pick(_emptyFallbacks);
    }

    // Detect if this is a follow-up referencing previous conversation
    final isFollowUp = history.isLikelyReferencingPreviousTopic(userMessage);

    // Resolve content context
    final resolvedContentId = contentId ?? history.mostRecentContentId;
    final lesson = resolvedContentId != null
        ? ContentRepository.findById(resolvedContentId)
        : null;
    final videos = lesson != null
        ? ContentRepository.getVideosForSubject(lesson.subject)
        : <VideoContent>[];
    final video = videos.isNotEmpty ? videos.first : null;

    // Analyze user message deeply
    final analysis = _analyzeMessage(userMessage, history);

    // If follow-up, route to follow-up handler
    if (isFollowUp && history.hasPreviousExchange) {
      return _generateFollowUp(analysis, lesson, video, profile, history, activeRecommendation);
    }

    // Route by primary intent
    switch (analysis.intent) {
      case _Intent.explain:
        return _generateExplain(analysis, lesson, video, profile, history);
      case _Intent.simplify:
        return _generateSimplify(analysis, lesson, profile);
      case _Intent.goDeeper:
        return _generateDeepDive(analysis, lesson, profile);
      case _Intent.whatNext:
        return _generateWhatNext(profile, activeRecommendation, history);
      case _Intent.whyRecommendation:
        return _generateWhyRecommendation(activeRecommendation, lesson, profile);
      case _Intent.greeting:
        return _generateGreeting(profile, history);
      case _Intent.unknown:
        return _generateClarification(lesson, history);
    }
  }

  _MessageAnalysis _analyzeMessage(String message, ConversationHistory history) {
    final lower = message.toLowerCase().trim();
    final isShort = message.length < 25;
    final depth = isShort ? ResponseDepth.brief : ResponseDepth.balanced;

    // Greeting detection
    if (RegExp(r'^(hi|hey|hello|good morning|good afternoon|good evening|yo|sup|hey there)\b').hasMatch(lower)) {
      return _MessageAnalysis(intent: _Intent.greeting, depth: depth);
    }

    // Simplify
    if (RegExp(r'\b(simplif|easier|simple|dumb down|el[yi]5|plainly|plain english|in simple terms)\b').hasMatch(lower)) {
      return _MessageAnalysis(intent: _Intent.simplify, depth: depth);
    }

    // Go deeper
    if (RegExp(r'\b(deeper?|more detail|advanced|elaborate|expand|dive|in[- ]depth|tell me more about|go deeper)\b').hasMatch(lower)) {
      return _MessageAnalysis(intent: _Intent.goDeeper, depth: ResponseDepth.detailed);
    }

    // What next
    if (RegExp(r'\b(what next|what should i|what now|what do|next step|what to study|suggest|recommend)\b').hasMatch(lower)) {
      return _MessageAnalysis(intent: _Intent.whatNext, depth: depth);
    }

    // Why recommendation
    if (RegExp(r'\bwhy.*(recommend|suggest|that|this|chose)\b').hasMatch(lower)) {
      return _MessageAnalysis(intent: _Intent.whyRecommendation, depth: depth);
    }

    // Explain (longer queries or direct ask)
    if (RegExp(r'\b(explain|what is|how do|how does|what does|why does|tell me about|describe|define|meaning|purpose|difference)\b').hasMatch(lower) ||
        lower.length > 30) {
      return _MessageAnalysis(intent: _Intent.explain, depth: lower.length > 80 ? ResponseDepth.detailed : ResponseDepth.balanced);
    }

    return _MessageAnalysis(intent: _Intent.unknown, depth: depth);
  }

  String _generateExplain(
    _MessageAnalysis analysis,
    ContentItem? lesson,
    VideoContent? video,
    LearnerProfile profile,
    ConversationHistory history,
  ) {
    if (lesson == null) {
      return 'Pick a lesson from Recommendations or tell me what subject you are working on. I can explain most topics in the course.';
    }

    final relevant = _selectRelevantSection(lesson.body, history.gatherQueryTerms());
    final opening = _pick(_explainOpenings);
    final conciseness = analysis.depth == ResponseDepth.brief
        ? _truncateToSentences(relevant, 2)
        : analysis.depth == ResponseDepth.detailed
            ? '$relevant\n\n${_expandWithAdditionalContent(lesson)}'
            : relevant;
    final videoHint = video != null
        ? _pick([' There is also a video on this.', ' You can also watch "${video.title}" for a visual walkthrough.', ' A video lesson "${video.title}" covers this too.'])
        : '';
    final closing = analysis.depth == ResponseDepth.brief ? '' : ' ${_pick(_explainClosings)}';

    final response = '$opening "$lesson.title": $conciseness$videoHint$closing';

    if (analysis.depth == ResponseDepth.detailed) {
      return '$response\n\nWould you like me to go over a specific part in more detail?';
    }
    return response;
  }

  String _generateSimplify(
    _MessageAnalysis analysis,
    ContentItem? lesson,
    LearnerProfile profile,
  ) {
    if (lesson == null) {
      return 'Which lesson would you like simplified? Tell me the title or pick one from Recommendations.';
    }

    final sentences = lesson.body.split(RegExp(r'(?<=[.!?])\s+'));
    final simplified = sentences.take(2).join(' ');
    final keyLine = lesson.tags.isNotEmpty
        ? 'Key ideas: ${lesson.tags.take(3).join(', ')}.'
        : '';
    final opener = lesson.body.length > 200
        ? _pick(_simplifyOpenings)
        : '';
    final response = '$opener$simplified${keyLine.isNotEmpty ? '\n\n$keyLine' : ''}';

    return '$response\n\nWould you like me to go over any part again?';
  }

  String _generateDeepDive(
    _MessageAnalysis analysis,
    ContentItem? lesson,
    LearnerProfile profile,
  ) {
    if (lesson == null) {
      return 'Pick a lesson first, then ask me to go deeper. I can pull out the advanced parts of any topic.';
    }

    final paragraphs = lesson.body.split('\n\n');
    final deeperContent = paragraphs.length > 2
        ? paragraphs.sublist(1).join('\n\n')
        : lesson.body;
    final truncated = deeperContent.length > 600
        ? '${deeperContent.substring(0, 597)}...'
        : deeperContent;

    return 'Going deeper into "${lesson.title}":\n\n$truncated\n\nWould you like me to connect this to another topic or keep going further?';
  }

  String _generateWhatNext(
    LearnerProfile profile,
    LearningRecommendation? recommendation,
    ConversationHistory history,
  ) {
    if (recommendation != null) {
      final lesson = recommendation.contentId != null
          ? ContentRepository.findById(recommendation.contentId!)
          : null;
      final title = lesson?.title ?? recommendation.title;
      final reason = recommendation.reason.isNotEmpty
          ? ' ${recommendation.reason}'
          : ' It matches your recent study patterns.';
      return 'Next up: "$title".$reason Want to start it now or hear about another option?';
    }

    if (history.totalExchanges > 0) {
      return 'You have been making progress. Try a quick quiz or a micro lesson to keep the momentum going. Want me to recommend something specific?';
    }

    final modeHints = ['Try a short quiz to test your knowledge.', 'A micro lesson is a good place to begin.', 'Start with flashcards for a quick review.'];
    return _pick(modeHints);
  }

  String _generateWhyRecommendation(
    LearningRecommendation? recommendation,
    ContentItem? lesson,
    LearnerProfile profile,
  ) {
    if (recommendation == null) {
      return 'I need to see a few study sessions before I can explain my reasoning. Try a lesson or quiz first.';
    }

    final title = lesson?.title ?? recommendation.title;
    final confidence = (recommendation.confidence * 100).round();
    if (recommendation.reason.isNotEmpty) {
      return 'I recommended "$title" because ${recommendation.reason.toLowerCase()}. I am ${confidence}% confident this fits your current learning style. Would you like to start it?';
    }
    return 'I recommended "$title" because it fits your recent progress and study preferences. Want to give it a try?';
  }

  String _generateFollowUp(
    _MessageAnalysis analysis,
    ContentItem? lesson,
    VideoContent? video,
    LearnerProfile profile,
    ConversationHistory history,
    LearningRecommendation? recommendation,
  ) {
    final lastTopic = history.extractLastTopic();
    final lastResponse = history.lastTutorResponse ?? '';
    final hasSubstance = lesson != null || lastTopic != null;

    if (!hasSubstance) {
      return _generateClarification(lesson, history);
    }

    final topicRef = lastTopic ?? lesson?.title ?? 'that topic';
    final link = _pick(_followUpLinks).replaceAll('{topic}', topicRef);

    // If user asked a short follow-up, expand on the previous response
    if (analysis.intent == _Intent.goDeeper || analysis.intent == _Intent.explain) {
      if (lesson != null) {
        return _generateDeepDive(analysis, lesson, profile);
      }
      return '$link I can go deeper if you pick a specific lesson to focus on.';
    }

    if (analysis.intent == _Intent.simplify) {
      if (lesson != null) {
        return _generateSimplify(analysis, lesson, profile);
      }
      return '$link Would you like me to simplify the last explanation?';
    }

    return '$link What part would you like to explore further?';
  }

  String _generateGreeting(LearnerProfile profile, ConversationHistory history) {
    if (history.totalExchanges > 0) {
      return _pick(_returnGreetings);
    }
    final name = profile.name.isNotEmpty ? ' ${profile.name}' : '';
    return 'Hi$name. I am your study assistant. Ask me about any lesson, or tell me what you want to learn today.';
  }

  String _generateClarification(ContentItem? lesson, ConversationHistory history) {
    // If we have a lesson context, ask about it specifically
    if (lesson != null) {
      return _pick([
        'Are you asking about "${lesson.title}" specifically, or something else?',
        'I can explain, simplify, or go deeper on "${lesson.title}". Which would help?',
        'Do you want me to go over "${lesson.title}" in a different way?',
      ]);
    }

    // If we have conversation history, reference it
    if (history.hasPreviousExchange) {
      return _pick([
        'I want to make sure I understand. Are you asking about what we just discussed, or a new topic?',
        'Could you tell me a bit more so I can point you to the right lesson?',
        'Are you looking for an explanation, a next step, or something else?',
      ]);
    }

    return _pick([
      'What subject are you working on? I can help with explanations, practice, or study suggestions.',
      'Tell me what you are studying and I will help you work through it.',
      'I can explain topics, simplify lessons, suggest what to study next, or go deeper on something you have already seen. What do you need?',
    ]);
  }

  String _selectRelevantSection(String body, List<String> queryTerms) {
    if (queryTerms.isEmpty) {
      final parts = body.split('\n\n');
      return parts.isNotEmpty ? parts.first : body;
    }

    final paragraphs = body.split('\n\n');
    if (paragraphs.length <= 1) return body;

    // Score each paragraph by keyword matches
    String best = paragraphs.first;
    int bestScore = 0;
    for (final para in paragraphs) {
      final lower = para.toLowerCase();
      int score = 0;
      for (final term in queryTerms) {
        if (lower.contains(term)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        best = para;
      }
    }
    return best;
  }

  String _expandWithAdditionalContent(ContentItem lesson) {
    final paragraphs = lesson.body.split('\n\n');
    if (paragraphs.length <= 1) return '';
    final extra = paragraphs.length > 2
        ? paragraphs.sublist(1, 3).join('\n\n')
        : paragraphs.last;
    return extra.length > 400 ? '${extra.substring(0, 397)}...' : extra;
  }

  String _truncateToSentences(String text, int count) {
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.length <= count) return text;
    return '${sentences.take(count).join(' ')}';
  }

  String _pick(List<String> options) => options[_random.nextInt(options.length)];

  // ---- Varied opening libraries ----

  static const _explainOpenings = [
    'Here is what I have on that.',
    'Let me break that down.',
    'Here is a clear explanation.',
    'I can explain that.',
    'Great question. Here is the gist.',
    'Here is what you need to know.',
    'Let me walk through that.',
    'Here is a straightforward explanation.',
  ];

  static const _explainClosings = [
    'Does that help clarify things?',
    'Let me know if you want more detail.',
    'Would you like me to go deeper on any part?',
    'I can simplify that further if needed.',
  ];

  static const _simplifyOpenings = [
    'In simpler terms: ',
    'Here is the key idea: ',
    'The main takeaway is: ',
    'Put simply, ',
    'Here is what that means: ',
  ];

  static const _followUpLinks = [
    'Building on what we just covered about {topic}, ',
    'To add more context to {topic}, ',
    'Great follow-up. Regarding {topic}, ',
    'Let me expand on {topic}. ',
    'Circling back to {topic}, ',
  ];

  static const _returnGreetings = [
    'Welcome back. What would you like to go over?',
    'Good to see you again. Where should we pick up?',
    'Back for more? I am ready. What is on your mind?',
    'Hello again. Want to continue where we left off?',
  ];

  static const _emptyFallbacks = [
    'I did not catch that. Could you rephrase?',
    'Say that again? I want to make sure I understand.',
    'I am not sure what you meant. Try asking in a different way.',
    'Could you tell me more about what you need?',
  ];
}

class _MessageAnalysis {
  final _Intent intent;
  final ResponseDepth depth;

  const _MessageAnalysis({required this.intent, required this.depth});
}

enum _Intent {
  explain,
  simplify,
  goDeeper,
  whatNext,
  whyRecommendation,
  greeting,
  unknown,
}
