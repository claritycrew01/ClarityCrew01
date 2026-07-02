import 'package:flutter/material.dart';
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
    return profile.prefersReducedVisuals ||
        profile.neurodivergentTraits.contains('sensory processing');
  }

  bool shouldReduceMotion(LearnerProfile profile) {
    return profile.prefersReducedMotion ||
        profile.neurodivergentTraits.contains('sensory processing') ||
        profile.neurodivergentTraits.contains('autism');
  }

  Duration getAnimationDuration(LearnerProfile profile) {
    if (shouldReduceMotion(profile)) return Duration.zero;
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

  bool shouldSimplifyContent(LearnerProfile profile) {
    return profile.neurodivergentTraits.contains('dyslexia') ||
        profile.neurodivergentTraits.contains('adhd');
  }

  String simplifyText(String text, LearnerProfile profile) {
    if (!shouldSimplifyContent(profile) && profile.depthPreference > 0.4) {
      return text;
    }
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.length <= 2) return text;
    return sentences.take(2).join(' ');
  }

  List<String> splitIntoSteps(String text, LearnerProfile profile) {
    if (!profile.neurodivergentTraits.contains('dyscalculia') &&
        !shouldSimplifyContent(profile)) {
      return [text];
    }
    final paragraphs = text.split(RegExp(r'\n\n+'));
    if (paragraphs.length <= 1) {
      final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
      if (sentences.length <= 2) return [text];
      return sentences;
    }
    return paragraphs;
  }

  /// True for ADHD, executive dysfunction — reduces mode choices on home screen.
  bool shouldReduceChoices(LearnerProfile profile) {
    return profile.neurodivergentTraits.contains('adhd') ||
        profile.neurodivergentTraits.contains('executive dysfunction');
  }

  /// True for autism — shows a "What happens next" preview before content.
  bool shouldShowSessionPreview(LearnerProfile profile) {
    return profile.neurodivergentTraits.contains('autism');
  }

  /// True for executive dysfunction — shows "Continue where you left off".
  bool shouldShowContinuePrompt(LearnerProfile profile) {
    return profile.neurodivergentTraits.contains('executive dysfunction');
  }

  /// True for dyscalculia — shows step-by-step worked examples.
  bool shouldShowStepByStep(LearnerProfile profile) {
    return profile.neurodivergentTraits.contains('dyscalculia');
  }

  /// True for anxiety — shows optional pause controls.
  bool shouldShowPauseControls(LearnerProfile profile) {
    return profile.neurodivergentTraits.contains('anxiety');
  }

  /// Returns the number of modes to show on the home screen grid.
  /// Reduces choices for ADHD and executive dysfunction.
  int getModeDisplayLimit(LearnerProfile profile) {
    if (shouldReduceChoices(profile)) return 4;
    return 7;
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

  /// Returns a (label, icon, color) per active trait for visible UI badges.
  List<(String label, IconData icon, Color color)> getPersonalizationBadges(
    LearnerProfile profile,
  ) {
    final badges = <(String, IconData, Color)>[];
    if (profile.neurodivergentTraits.contains('adhd')) {
      badges.add(('Focus Mode', Icons.bolt_outlined, const Color(0xFFE76F51)));
    }
    if (profile.neurodivergentTraits.contains('autism')) {
      badges.add(('Routine Mode', Icons.loop_rounded, const Color(0xFF457B9D)));
    }
    if (profile.neurodivergentTraits.contains('dyslexia')) {
      badges.add(('Reading Mode', Icons.text_fields, const Color(0xFF7B68EE)));
    }
    if (profile.neurodivergentTraits.contains('dyspraxia')) {
      badges.add(('Large Controls', Icons.touch_app, const Color(0xFFE9C46A)));
    }
    if (profile.neurodivergentTraits.contains('dyscalculia')) {
      badges.add(('Visual Math', Icons.grid_on_rounded, const Color(0xFF52B788)));
    }
    if (profile.neurodivergentTraits.contains('anxiety')) {
      badges.add(('Calm Mode', Icons.spa_outlined, const Color(0xFF2A9D8F)));
    }
    if (profile.neurodivergentTraits.contains('sensory processing')) {
      badges.add(('Low Stimulation', Icons.remove_red_eye_outlined, const Color(0xFF6C757D)));
    }
    if (profile.neurodivergentTraits.contains('executive dysfunction')) {
      badges.add(('Guided Mode', Icons.map_outlined, const Color(0xFFF4A261)));
    }
    return badges;
  }

  /// Returns a short descriptive summary per active trait.
  List<String> getPersonalizationDescriptions(LearnerProfile profile) {
    final descs = <String>[];
    if (profile.neurodivergentTraits.contains('adhd')) {
      descs.add('Shorter steps, focus timer, and one-next-action highlighting.');
    }
    if (profile.neurodivergentTraits.contains('autism')) {
      descs.add('Predictable layout, clear labels, and session previews.');
    }
    if (profile.neurodivergentTraits.contains('dyslexia')) {
      descs.add('Enhanced font clarity, simplified text, and reading support.');
    }
    if (profile.neurodivergentTraits.contains('dyspraxia')) {
      descs.add('Larger touch targets, generous spacing, and forgiving layout.');
    }
    if (profile.neurodivergentTraits.contains('dyscalculia')) {
      descs.add('Numbers explained visually, step-by-step worked examples.');
    }
    if (profile.neurodivergentTraits.contains('anxiety')) {
      descs.add('Reassuring tone, clear progress, pause-and-break controls.');
    }
    if (profile.neurodivergentTraits.contains('sensory processing')) {
      descs.add('Reduced animations, calmer colors, and wider spacing.');
    }
    if (profile.neurodivergentTraits.contains('executive dysfunction')) {
      descs.add('One-step guidance, task breakdown, and continue-where-you-left-off.');
    }
    return descs;
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
    if (profile.neurodivergentTraits.contains('dyspraxia')) {
      accommodations.addAll([
        'Increase tap target sizes',
        'Add generous spacing between controls',
        'Simplify navigation steps',
        'Make drag interactions optional',
      ]);
    }
    if (profile.neurodivergentTraits.contains('dyscalculia')) {
      accommodations.addAll([
        'Explain numbers with extra context',
        'Break calculations into visual steps',
        'Show worked examples before practice',
        'Reduce unexplained numeric density',
      ]);
    }
    if (profile.neurodivergentTraits.contains('anxiety')) {
      accommodations.addAll([
        'Use reassuring, low-pressure tone',
        'Show exactly what happens next',
        'Provide optional pause and skip controls',
        'Avoid sudden changes or surprises',
      ]);
    }
    if (profile.neurodivergentTraits.contains('sensory processing')) {
      accommodations.addAll([
        'Reduce bright colors and flashing elements',
        'Provide a visual comfort setting',
        'Increase spacing between elements',
        'Offer a distraction-free layout',
      ]);
    }
    if (profile.neurodivergentTraits.contains('executive dysfunction')) {
      accommodations.addAll([
        'Show one small step at a time',
        'Add guided start button',
        'Provide checkpoints and visible progress',
        'Add continue-where-you-left-off',
      ]);
    }
    return accommodations;
  }
}
