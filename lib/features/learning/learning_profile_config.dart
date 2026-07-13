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

  // Typography & reading
  final double lineHeight;
  final double letterSpacing;
  final String? fontFamily;
  final bool increaseWordSpacing;

  // Dyslexia — structured literacy
  final bool chunkedReading;
  final bool multisensoryCues;
  final bool showReadAloud;

  // ADHD — focus & attention
  final bool showProgressBar;
  final bool persistPosition;
  final bool showFocusMode;

  // Dysgraphia — writing support
  final bool showWritingTemplates;

  // Dyscalculia — math scaffolding
  final bool visualMathBar;
  final bool showWorkedExamples;
  final bool scaffoldHints;
  final bool stepByStep;

  // Autism — predictability
  final bool showSectionLabels;
  final bool consistentLayout;

  // Shared
  final bool reduceVisualElements;
  final bool showTags;
  final bool showFlashcards;
  final bool collapseExtraContent;
  final bool autoSimplify;
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
  final bool scaffoldedRelease;

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
    this.chunkedReading = false,
    this.multisensoryCues = false,
    this.showReadAloud = false,
    this.showProgressBar = false,
    this.persistPosition = false,
    this.showFocusMode = false,
    this.showWritingTemplates = false,
    this.visualMathBar = false,
    this.showWorkedExamples = false,
    this.scaffoldHints = false,
    this.stepByStep = false,
    this.showSectionLabels = false,
    this.consistentLayout = false,
    this.reduceVisualElements = false,
    this.showTags = true,
    this.showFlashcards = true,
    this.collapseExtraContent = false,
    this.autoSimplify = false,
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
    this.scaffoldedRelease = false,
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
      );
    case LearningAccessibilityProfile.dyslexia:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.dyslexia,
        label: 'Dyslexia',
        icon: Icons.text_fields,
        color: Color(0xFF7B68EE),
        description: 'Structured literacy: chunked reading, multisensory cues, read-aloud support',
        lineHeight: 2.0,
        letterSpacing: 1.2,
        fontFamily: 'monospace',
        increaseWordSpacing: true,
        autoSimplify: true,
        chunkedReading: true,
        multisensoryCues: true,
        showReadAloud: true,
        reduceVisualElements: true,
        showFlashcards: false,
        showTags: false,
        showSectionLabels: true,
      );
    case LearningAccessibilityProfile.adhd:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.adhd,
        label: 'ADHD',
        icon: Icons.bolt_outlined,
        color: Color(0xFFE76F51),
        description: 'Focus mode: one action at a time, progress bar, quick re-entry',
        reduceVisualElements: true,
        showTags: false,
        showFlashcards: false,
        collapseExtraContent: true,
        showOneActionAtATime: true,
        showProgressIndication: true,
        showProgressBar: true,
        persistPosition: true,
        showFocusMode: true,
        showReminders: true,
        reduceChoices: true,
      );
    case LearningAccessibilityProfile.dysgraphia:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.dysgraphia,
        label: 'Dysgraphia',
        icon: Icons.keyboard_outlined,
        color: Color(0xFFE9C46A),
        description: 'Typed input, speech-to-text, writing templates, word suggestions',
        useTextInputInsteadOfChoices: true,
        showSpeechToText: true,
        showSentenceStarters: true,
        showWordPrediction: true,
        showWritingTemplates: true,
        showTags: false,
      );
    case LearningAccessibilityProfile.dyscalculia:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.dyscalculia,
        label: 'Dyscalculia',
        icon: Icons.grid_on_rounded,
        color: Color(0xFF52B788),
        description: 'Visual math bar, step-by-step with worked examples and scaffolded hints',
        stepByStep: true,
        visualMathBar: true,
        showWorkedExamples: true,
        scaffoldHints: true,
        showProgressIndication: true,
        showSectionLabels: true,
      );
    case LearningAccessibilityProfile.autism:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.autism,
        label: 'Autism',
        icon: Icons.loop_rounded,
        color: Color(0xFF457B9D),
        description: 'Predictable layout, session preview, clear section labels, no surprises',
        showSessionPreview: true,
        showPauseControls: true,
        reduceMotion: true,
        reduceAnimation: true,
        showSectionLabels: true,
        consistentLayout: true,
        showTags: false,
      );
    case LearningAccessibilityProfile.sensoryProcessing:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.sensoryProcessing,
        label: 'Sensory',
        icon: Icons.remove_red_eye_outlined,
        color: Color(0xFF6C757D),
        description: 'Low stimulation: calm palette, collapsed extras, no motion',
        reduceVisualElements: true,
        collapseExtraContent: true,
        reduceMotion: true,
        reduceAnimation: true,
        calmColors: true,
        showTags: false,
        showFlashcards: false,
      );
    case LearningAccessibilityProfile.executiveDysfunction:
      return const LearningProfileConfig(
        profile: LearningAccessibilityProfile.executiveDysfunction,
        label: 'Executive',
        icon: Icons.map_outlined,
        color: Color(0xFFF4A261),
        description: 'I Do / We Do / You Do scaffold, checklist, one action at a time',
        scaffoldedRelease: true,
        showChecklist: true,
        showNextStepProminent: true,
        showReminders: true,
        showProgressIndication: true,
        showProgressBar: true,
        showOneActionAtATime: true,
        reduceChoices: true,
        showSessionSummaryOnComplete: true,
        reduceVisualElements: true,
        showTags: false,
        showFlashcards: false,
      );
  }
}

List<LearningAccessibilityProfile> get availableProfiles =>
    LearningAccessibilityProfile.values;
