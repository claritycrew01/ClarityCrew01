import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/learner_profile.dart';
import '../models/learning_recommendation.dart';
import '../models/interaction_event.dart';
import '../models/session_record.dart';
import '../services/adaptive_ai_engine.dart';
import '../services/content_mode_selector.dart';
import '../services/recommendation_engine.dart';
import '../services/session_analyzer.dart';
import '../services/progress_tracker.dart';
import '../services/focus_support_service.dart';
import '../services/accessibility_service.dart';

class AppState extends ChangeNotifier {
  final AdaptiveAIEngine aiEngine = AdaptiveAIEngine();
  final ContentModeSelector modeSelector = ContentModeSelector();
  final RecommendationEngine recommendationEngine = RecommendationEngine();
  final SessionAnalyzer sessionAnalyzer = SessionAnalyzer();
  final ProgressTracker progressTracker = ProgressTracker();
  final FocusSupportService focusService = FocusSupportService();
  final AccessibilityService accessibilityService = AccessibilityService();

  LearningRecommendation? _currentRecommendation;
  List<LearningRecommendation> _recommendations = [];
  bool _isDarkMode = false;
  bool _isProcessing = false;
  List<SessionRecord> _recentSessions = [];

  void updateSessionData(List<SessionRecord> sessions) {
    _recentSessions = sessions;
  }

  LearningRecommendation? get currentRecommendation => _currentRecommendation;
  List<LearningRecommendation> get recommendations => _recommendations;
  bool get isDarkMode => _isDarkMode;
  bool get isProcessing => _isProcessing;

  // Accessibility / personalization helpers exposed to all screens
  int tapTargetSize(LearnerProfile profile) =>
      accessibilityService.getRecommendedTapTargetSize(profile);
  String simplifyText(String text, LearnerProfile profile) =>
      accessibilityService.simplifyText(text, profile);
  bool shouldReduceMotion(LearnerProfile profile) =>
      accessibilityService.shouldReduceMotion(profile);
  Duration animationDuration(LearnerProfile profile) =>
      accessibilityService.getAnimationDuration(profile);
  List<String> accommodationsFor(LearnerProfile profile) =>
      accessibilityService.getRecommendedAccommodations(profile);
  List<(String label, IconData icon, Color color)> badgesFor(
          LearnerProfile profile) =>
      accessibilityService.getPersonalizationBadges(profile);
  List<String> descriptionsFor(LearnerProfile profile) =>
      accessibilityService.getPersonalizationDescriptions(profile);

  Future<LearnerProfile> processInteraction({
    required LearnerProfile profile,
    required String contentType,
    required String interactionType,
    bool wasSuccessful = true,
    int? score,
    double durationSeconds = 0,
    String sessionId = '',
    String contentId = '',
  }) async {
    _isProcessing = true;
    notifyListeners();

    final event = InteractionEvent(
      id: UniqueKey().toString(),
      sessionId: sessionId,
      learnerId: profile.id,
      contentType: contentType,
      contentId: contentId,
      interactionType: interactionType,
      wasSuccessful: wasSuccessful,
      score: score,
      durationSeconds: durationSeconds,
    );

    final updatedProfile = aiEngine.updateFromInteraction(profile, event);
    _currentRecommendation =
        recommendationEngine.generateRecommendation(updatedProfile, _recentSessions);

    _isProcessing = false;
    notifyListeners();
    return updatedProfile;
  }

  void generateNewRecommendations(LearnerProfile profile) {
    _recommendations = recommendationEngine
        .generateMultipleRecommendations(profile, _recentSessions);
    _currentRecommendation = _recommendations.isNotEmpty
        ? _recommendations.first
        : null;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  LearningMode predictBestMode(LearnerProfile profile) {
    return modeSelector.predictBestMode(profile);
  }
}
