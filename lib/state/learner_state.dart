import 'package:flutter/foundation.dart';
import '../models/learner_profile.dart';
import '../persistence/local_storage_repository.dart';

class LearnerState extends ChangeNotifier {
  final LocalStorageRepository _repo = LocalStorageRepository();

  LearnerProfile _profile = LearnerProfile(id: 'default');
  bool _isLoading = true;

  LearnerProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isNewUser => _profile.isNewUser;

  LearnerState() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final saved = await _repo.loadLearnerProfile();
      if (saved != null) {
        _profile = saved;
      }
    } catch (_) {
      // Use default profile on load failure
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(LearnerProfile updated) async {
    _profile = updated;
    await _repo.saveLearnerProfile(_profile);
    notifyListeners();
  }

  Future<void> completeOnboarding(String name, List<String> traits) async {
    _profile = _profile.copyWith(
      name: name,
      neurodivergentTraits: traits,
      isNewUser: false,
      lastUpdated: DateTime.now(),
    );
    await _repo.saveLearnerProfile(_profile);
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    _profile = _profile.copyWith(name: name, lastUpdated: DateTime.now());
    await _repo.saveLearnerProfile(_profile);
    notifyListeners();
  }

  Future<void> updateModeWeights(Map<String, double> weights) async {
    final modeWeights = <LearningMode, double>{};
    for (final entry in weights.entries) {
      final mode = LearningMode.values.byName(entry.key);
      modeWeights[mode] = entry.value;
    }
    _profile = _profile.copyWith(
      modeWeights: modeWeights,
      lastUpdated: DateTime.now(),
    );
    await _repo.saveLearnerProfile(_profile);
    notifyListeners();
  }

  Future<void> updateAccessibility({
    bool? reducedMotion,
    bool? reducedVisuals,
    bool? highContrast,
    bool? simplifiedText,
    double? lineSpacing,
    double? fontSizeMultiplier,
  }) async {
    _profile = _profile.copyWith(
      prefersReducedMotion: reducedMotion ?? _profile.prefersReducedMotion,
      prefersReducedVisuals: reducedVisuals ?? _profile.prefersReducedVisuals,
      prefersHighContrast: highContrast ?? _profile.prefersHighContrast,
      prefersSimplifiedText: simplifiedText ?? _profile.prefersSimplifiedText,
      lineSpacing: lineSpacing ?? _profile.lineSpacing,
      fontSizeMultiplier: fontSizeMultiplier ?? _profile.fontSizeMultiplier,
      lastUpdated: DateTime.now(),
    );
    await _repo.saveLearnerProfile(_profile);
    notifyListeners();
  }

  void setProfile(LearnerProfile profile) {
    _profile = profile;
    notifyListeners();
  }
}
