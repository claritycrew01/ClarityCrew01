import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

enum LearningAccessibilityProfile {
  none,
  dyslexia,
  adhd,
  dysgraphia,
  dyscalculia,
  autism,
  sensoryProcessing,
  executiveDysfunction,
}

class LearningProfileConfig {
  final LearningAccessibilityProfile profile;
  final String label;
  final IconData icon;
  final Color color;
  final String description;

  final double lineHeight;
  final double letterSpacing;
  final String? fontFamily;
  final bool increaseWordSpacing;

  final bool reduceVisualElements;
  final bool showTags;
  final bool showFlashcards;
  final bool collapseExtraContent;

  final bool autoSimplify;
  final bool stepByStep;
  final bool showCalculator;
  final bool showWorkedExamples;
  final bool scaffoldHints;

  final bool useTextInputInsteadOfChoices;
  final bool showSpeechToText;
  final bool showSentenceStarters;
  final bool showWordPrediction;

  final bool showOneActionAtATime;
  final bool showProgressIndication;
  final bool showSessionPreview;
  final bool showPauseControls;
  final bool reduceChoices;

  final bool reduceMotion;
  final bool reduceAnimation;
  final bool calmColors;

  final bool showChecklist;
  final bool showNextStepProminent;
  final bool showReminders;
  final bool showSessionSummaryOnComplete;

  final bool showHeader;
  final bool sectionBreakAfterHeader;

  const LearningProfileConfig({
    required this.profile,
    required this.label,
    required this.icon,
    required this.color,
    this.description = '',
    this.lineHeight = 1.6,
    this.letterSpacing = 0.0,
    this.fontFamily,
    this.increaseWordSpacing = false,
    this.reduceVisualElements = false,
    this.showTags = true,
    this.showFlashcards = true,
    this.collapseExtraContent = false,
    this.autoSimplify = false,
    this.stepByStep = false,
    this.showCalculator = false,
    this.showWorkedExamples = false,
    this.scaffoldHints = false,
    this.useTextInputInsteadOfChoices = false,
    this.showSpeechToText = false,
    this.showSentenceStarters = false,
    this.showWordPrediction = false,
    this.showOneActionAtATime = false,
    this.showProgressIndication = false,
    this.showSessionPreview = false,
    this.showPauseControls = false,
    this.reduceChoices = false,
    this.reduceMotion = false,
    this.reduceAnimation = false,
    this.calmColors = false,
    this.showChecklist = false,
    this.showNextStepProminent = false,
    this.showReminders = false,
    this.showSessionSummaryOnComplete = true,
    this.showHeader = true,
    this.sectionBreakAfterHeader = true,
  });
}

LearningProfileConfig getProfileConfig(LearningAccessibilityProfile profile) {
  switch (profile) {
    case LearningAccessibilityProfile.none:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.none,
        label: 'None',
        icon: Icons.touch_app,
        color: AppColors.calmTeal,
        sectionBreakAfterHeader: true,
      );
    case LearningAccessibilityProfile.dyslexia:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.dyslexia,
        label: 'Dyslexia',
        icon: Icons.text_fields,
        color: Color(0xFF7B68EE),
        description: 'Readable fonts, wide spacing, reduced distractions',
        lineHeight: 2.0,
        letterSpacing: 1.2,
        fontFamily: 'monospace',
        increaseWordSpacing: true,
        autoSimplify: true,
        reduceVisualElements: true,
        showFlashcards: false,
        showTags: false,
        sectionBreakAfterHeader: true,
      );
    case LearningAccessibilityProfile.adhd:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.adhd,
        label: 'ADHD',
        icon: Icons.bolt_outlined,
        color: Color(0xFFE76F51),
        description: 'Simplified layout, one action at a time, clear focus',
        reduceVisualElements: true,
        showTags: false,
        showFlashcards: false,
        collapseExtraContent: true,
        showOneActionAtATime: true,
        showProgressIndication: true,
        reduceChoices: true,
        sectionBreakAfterHeader: true,
      );
    case LearningAccessibilityProfile.dysgraphia:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.dysgraphia,
        label: 'Dysgraphia',
        icon: Icons.keyboard_outlined,
        color: Color(0xFFE9C46A),
        description: 'Type or speak answers, templates, word suggestions',
        useTextInputInsteadOfChoices: true,
        showSpeechToText: true,
        showSentenceStarters: true,
        showWordPrediction: true,
        showTags: false,
        sectionBreakAfterHeader: true,
      );
    case LearningAccessibilityProfile.dyscalculia:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.dyscalculia,
        label: 'Dyscalculia',
        icon: Icons.grid_on_rounded,
        color: Color(0xFF52B788),
        description: 'Step-by-step, visual supports, worked examples',
        stepByStep: true,
        showCalculator: true,
        showWorkedExamples: true,
        scaffoldHints: true,
        showProgressIndication: true,
        sectionBreakAfterHeader: true,
      );
    case LearningAccessibilityProfile.autism:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.autism,
        label: 'Autism',
        icon: Icons.loop_rounded,
        color: Color(0xFF457B9D),
        description: 'Predictable layout, clear instructions, no surprises',
        showSessionPreview: true,
        showPauseControls: true,
        reduceMotion: true,
        reduceAnimation: true,
        showTags: false,
        sectionBreakAfterHeader: true,
      );
    case LearningAccessibilityProfile.sensoryProcessing:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.sensoryProcessing,
        label: 'Sensory',
        icon: Icons.remove_red_eye_outlined,
        color: Color(0xFF6C757D),
        description: 'Low stimulation, calm colors, collapse extras',
        reduceVisualElements: true,
        collapseExtraContent: true,
        reduceMotion: true,
        reduceAnimation: true,
        calmColors: true,
        showTags: false,
        showFlashcards: false,
        sectionBreakAfterHeader: true,
      );
    case LearningAccessibilityProfile.executiveDysfunction:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.executiveDysfunction,
        label: 'Executive',
        icon: Icons.map_outlined,
        color: Color(0xFFF4A261),
        description: 'Step-by-step checklist, one task at a time, clear progress',
        showChecklist: true,
        showNextStepProminent: true,
        showReminders: true,
        showProgressIndication: true,
        showOneActionAtATime: true,
        reduceChoices: true,
        showSessionSummaryOnComplete: true,
        reduceVisualElements: true,
        showTags: false,
        showFlashcards: false,
        sectionBreakAfterHeader: true,
      );
  }
}

List<LearningAccessibilityProfile> get availableProfiles =>
    LearningAccessibilityProfile.values;
