import '../../models/learner_profile.dart';
import '../../models/learning_recommendation.dart';
import '../../models/tutor_message.dart';
import 'conversation_history.dart';
import 'response_generator.dart';

/// Entry point for AI tutor responses.
///
/// Primary response path uses [ResponseGenerator] for dynamic,
/// context-aware replies. Only falls back to static text for
/// empty input, safety / system-failure edge cases, or when
/// the generator returns an empty response.
class TutorService {
  final ResponseGenerator _generator = ResponseGenerator();

  TutorMessage respond({
    required String userMessage,
    required LearnerProfile profile,
    required List<TutorMessage> conversationHistory,
    String? contentId,
    LearningRecommendation? activeRecommendation,
  }) {
    final history = ConversationHistory(conversationHistory);
    final text = _generateSafe(userMessage, profile, history, contentId, activeRecommendation);

    return TutorMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'tutor',
      text: text,
      contentId: contentId,
      timestamp: DateTime.now(),
    );
  }

  String _generateSafe(
    String userMessage,
    LearnerProfile profile,
    ConversationHistory history,
    String? contentId,
    LearningRecommendation? activeRecommendation,
  ) {
    final lower = userMessage.trim().toLowerCase();

    // ---- Edge-case / safety fallbacks (NOT the primary path) ----
    if (lower.isEmpty) {
      return 'I did not receive any text. Try typing your question again.';
    }

    if (_containsHarmfulContent(lower)) {
      return 'I am here to help with studying. Let me know if you have a question about a lesson or topic.';
    }

    // ---- Primary path: dynamic generation ----
    try {
      final response = _generator.generate(
        userMessage: userMessage,
        profile: profile,
        history: history,
        contentId: contentId,
        activeRecommendation: activeRecommendation,
      );

      // If generator somehow returned empty, use generic fallback
      if (response.trim().isEmpty) {
        return 'I am not sure I followed that. Could you rephrase? I can explain lessons, simplify topics, or suggest what to study next.';
      }

      return response;
    } catch (_) {
      // System-failure fallback (rare)
      return 'I hit a snag. Try asking your question again in a different way.';
    }
  }

  bool _containsHarmfulContent(String message) {
    return RegExp(
      r'\b(swear|curse|insult|attack|harass|threat|abuse|violen|harm|kill|'
      r'destroy|hack|illegal|weapon|drug|suicid|selfharm)\b',
      caseSensitive: false,
    ).hasMatch(message);
  }
}
