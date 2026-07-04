import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/learner_profile.dart';
import '../models/learning_recommendation.dart';
import '../models/interaction_event.dart';
import '../models/session_record.dart';
import '../services/adaptive_ai_engine.dart';
import '../services/content_mode_selector.dart';
import '../services/recommendation_engine.dart';
import '../services/progress_tracker.dart';
import '../services/accessibility_service.dart';
import '../services/focus_support_service.dart';
import '../persistence/shared_preferences_adapter.dart';

class AppState extends ChangeNotifier {
  final AdaptiveAIEngine aiEngine = AdaptiveAIEngine();
  final ContentModeSelector modeSelector = ContentModeSelector();
  final RecommendationEngine recommendationEngine = RecommendationEngine();
  final ProgressTracker progressTracker = ProgressTracker();
  final AccessibilityService accessibilityService = AccessibilityService();
  final FocusSupportService focusService = FocusSupportService();

  LearningRecommendation? _currentRecommendation;
  List<LearningRecommendation> _recommendations = [];
  bool _isDarkMode = false;
  bool _isProcessing = false;
  List<SessionRecord> _recentSessions = [];
  bool _soundEnabled = true;
  bool _hapticEnabled = true;

  void updateSessionData(List<SessionRecord> sessions) {
    _recentSessions = sessions;
  }

  LearningRecommendation? get currentRecommendation => _currentRecommendation;
  List<LearningRecommendation> get recommendations => _recommendations;
  bool get isDarkMode => _isDarkMode;
  bool get isProcessing => _isProcessing;
  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;

  // Accessibility / personalization helpers exposed to all screens
  int tapTargetSize(LearnerProfile profile) =>
      accessibilityService.getRecommendedTapTargetSize(profile);
  String simplifyText(String text, LearnerProfile profile) =>
      accessibilityService.simplifyText(text, profile);
  bool shouldReduceMotion(LearnerProfile profile) =>
      accessibilityService.shouldReduceMotion(profile);
  bool shouldSimplifyContent(LearnerProfile profile) =>
      accessibilityService.shouldSimplifyContent(profile);
  bool shouldSimplifyVisuals(LearnerProfile profile) =>
      accessibilityService.shouldSimplifyVisuals(profile);
  bool shouldReduceChoices(LearnerProfile profile) =>
      accessibilityService.shouldReduceChoices(profile);
  bool shouldShowSessionPreview(LearnerProfile profile) =>
      accessibilityService.shouldShowSessionPreview(profile);
  bool shouldShowContinuePrompt(LearnerProfile profile) =>
      accessibilityService.shouldShowContinuePrompt(profile);
  bool shouldShowStepByStep(LearnerProfile profile) =>
      accessibilityService.shouldShowStepByStep(profile);
  bool shouldShowPauseControls(LearnerProfile profile) =>
      accessibilityService.shouldShowPauseControls(profile);
  List<String> splitIntoSteps(String text, LearnerProfile profile) =>
      accessibilityService.splitIntoSteps(text, profile);
  int getModeDisplayLimit(LearnerProfile profile) =>
      accessibilityService.getModeDisplayLimit(profile);
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
    SharedPrefsAdapter.setBool('dark_mode', value);
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    SharedPrefsAdapter.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    SharedPrefsAdapter.setBool('sound_enabled', value);
    notifyListeners();
  }

  void setHapticEnabled(bool value) {
    _hapticEnabled = value;
    SharedPrefsAdapter.setBool('haptic_enabled', value);
    notifyListeners();
  }

  AppState() {
    final darkMode = SharedPrefsAdapter.getBool('dark_mode');
    if (darkMode != null) _isDarkMode = darkMode;
    final sound = SharedPrefsAdapter.getBool('sound_enabled');
    if (sound != null) _soundEnabled = sound;
    final haptic = SharedPrefsAdapter.getBool('haptic_enabled');
    if (haptic != null) _hapticEnabled = haptic;
  }

  LearningMode predictBestMode(LearnerProfile profile) {
    return modeSelector.predictBestMode(profile);
  }
}
