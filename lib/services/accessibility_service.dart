import '../models/learner_profile.dart';
import '../models/content_item.dart';

class AccessibilityService {
  double getEffectiveFontSize(
    LearnerProfile profile,
    double baseSize,
  ) {
    return baseSize * profile.fontSizeMultiplier;
  }

  bool shouldSimplifyVisuals(LearnerProfile profile) {
    return profile.prefersReducedVisuals;
  }

  bool shouldReduceMotion(LearnerProfile profile) {
    return profile.prefersReducedMotion;
  }

  Duration getAnimationDuration(LearnerProfile profile) {
    if (profile.prefersReducedMotion) return Duration.zero;
    return const Duration(milliseconds: 300);
  }

  int getRecommendedTapTargetSize(LearnerProfile profile) {
    if (profile.neurodivergentTraits.contains('adhd') ||
        profile.neurodivergentTraits.contains('dyspraxia')) {
      return 56;
    }
    return 48;
  }

  double getContentComplexityFactor(LearnerProfile profile) {
    if (profile.depthPreference < 0.3) return 0.6;
    if (profile.depthPreference < 0.6) return 0.8;
    return 1.0;
  }

  String simplifyText(String text, LearnerProfile profile) {
    if (!profile.neurodivergentTraits.contains('dyslexia') &&
        profile.depthPreference > 0.4) {
      return text;
    }
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.length <= 2) return text;
    return sentences.take(2).join(' ');
  }

  ContentItem adaptContentForAccessibility(
    ContentItem item,
    LearnerProfile profile,
  ) {
    if (profile.neurodivergentTraits.contains('dyslexia') ||
        profile.prefersReducedVisuals) {
      return item.copyWith(
        body: simplifyText(item.body, profile),
      );
    }
    return item;
  }

  List<String> getRecommendedAccommodations(LearnerProfile profile) {
    final accommodations = <String>[];
    if (profile.neurodivergentTraits.contains('adhd')) {
      accommodations.addAll([
        'Break tasks into small chunks',
        'Use timers for focus sessions',
        'Provide frequent positive feedback',
        'Minimize on-screen distractions',
      ]);
    }
    if (profile.neurodivergentTraits.contains('autism')) {
      accommodations.addAll([
        'Keep instructions clear and literal',
        'Provide predictable routines',
        'Avoid figurative language',
        'Offer sensory-friendly visuals',
      ]);
    }
    if (profile.neurodivergentTraits.contains('dyslexia')) {
      accommodations.addAll([
        'Use large, readable fonts',
        'Avoid long paragraphs',
        'Use bullet points',
        'Provide audio alternatives',
      ]);
    }
    return accommodations;
  }
}
