import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../models/learner_profile.dart';
import '../../state/learner_state.dart';
import '../../state/session_state.dart';
import '../../state/app_state.dart';
import '../../models/content_item.dart';
import '../../models/interaction_event.dart';
import '../../services/content/content_repository.dart';
import '../ai_tutor/ai_tutor_screen.dart';
import 'learning_profile_config.dart';
import '../../services/speech_service.dart';

class LearningSessionScreen extends StatefulWidget {
  final String? initialLessonId;
  final String? initialContentId;

  const LearningSessionScreen({super.key, this.initialLessonId, this.initialContentId});

  @override
  State<LearningSessionScreen> createState() => _LearningSessionScreenState();
}

class _LearningSessionScreenState extends State<LearningSessionScreen> {
  final _contentLibrary = <ContentItem>[];
  bool _isInitialized = false;
  bool _sessionInitialized = false;
  bool _showSummary = false;
  bool _useSimplified = false;
  String? _simplifiedBody;
  bool _showPreview = false;
  bool _showPause = false;
  int _currentStep = 0;
  List<String> _steps = [];
  String? _simplifiedForContentId;
  LearningAccessibilityProfile _activeProfile = LearningAccessibilityProfile.none;
  final _answerController = TextEditingController();
  final _sentenceStarters = [
    'The main idea is',
    'This connects to',
    'One example is',
    'In summary',
    'A key difference is',
    'This matters because',
    'First,',
    'Another important point',
  ];
  List<bool> _checklistItems = [];
  bool _showChecklist = false;
  int _taskStep = 0;
  int _currentChunk = 0;
  List<String> _readingChunks = [];
  final _scrollController = ScrollController();
  bool _hintsRevealed = false;
  int _hintLevel = 0;
  bool _focusTimerActive = false;
  int _templateIndex = 0;
  int _scaffoldStage = 0;
  final _speechService = SpeechService();
  bool _isListening = false;
  String _transcribedText = '';

  @override
  void initState() {
    super.initState();
    _contentLibrary.addAll(ContentRepository.getAll());
    _isInitialized = true;
  }

  @override
  void dispose() {
    _speechService.stopListening();
    _answerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sessionInitialized) {
      final appState = context.read<AppState>();
      final profile = context.read<LearnerState>().profile;
      context.read<SessionState>().setActiveContent(
            _contentLibrary,
            startContentId: widget.initialLessonId,
          );
      _sessionInitialized = true;
      if (profile.neurodivergentTraits.isNotEmpty) {
        _activeProfile = _traitsToProfile(profile.neurodivergentTraits);
      }
      final config = getProfileConfig(_activeProfile);
      if (config.showSessionPreview) {
        _showPreview = true;
      }
      if (config.autoSimplify && _contentLibrary.isNotEmpty) {
        _simplifiedForContentId = _contentLibrary.first.id;
        _simplifyContent(_contentLibrary.first);
      }
      if (config.stepByStep && _contentLibrary.isNotEmpty) {
        _steps = appState.splitIntoSteps(_contentLibrary.first.body, profile);
        _currentStep = 0;
      }
      if (config.showChecklist && _contentLibrary.isNotEmpty) {
        _initChecklist(_contentLibrary.first);
      }
      if (config.chunkedReading && _contentLibrary.isNotEmpty) {
        _initReadingChunks(_contentLibrary.first);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_contentLibrary.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learning Session')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined, size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No lessons available.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    final appState = context.watch<AppState>();
    final learnerState = context.watch<LearnerState>();
    final sessionState = context.watch<SessionState>();
    final profile = learnerState.profile;
    final content = sessionState.currentContent ??
        _contentLibrary.first;
    final config = getProfileConfig(_activeProfile);

    if (config.autoSimplify && _simplifiedForContentId != content.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _simplifiedForContentId = content.id;
        _simplifyContent(content);
      });
    }

    if (_showSummary) {
      return _buildSummaryScreen(context, sessionState);
    }

    if (config.showSessionPreview && !_showPreview && !_sessionInitialized) {
      _showPreview = true;
    }

    if (_showPreview) {
      return _buildPreviewScreen(context, content, profile);
    }

    if (_showPause) {
      return _buildPauseOverlay(context, sessionState);
    }

    if (config.stepByStep && _contentLibrary.isNotEmpty) {
      _steps = appState.splitIntoSteps(content.body, profile);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(content.contentType.replaceAll('_', ' ')),
        centerTitle: true,
        actions: [
          if (config.showPauseControls)
            IconButton(
              icon: const Icon(Icons.pause_circle_outline),
              tooltip: 'Pause',
              onPressed: () => setState(() => _showPause = true),
            ),
          TextButton(
            onPressed: () => setState(() => _showSummary = true),
            child: const Text('End Session'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: config.persistPosition ? _scrollController : null,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (config.showHeader) _buildContentHeader(content, config),
              const SizedBox(height: 20),
              _buildProfileSelector(config),
              if (config.sectionBreakAfterHeader) const SizedBox(height: 12),
              if (config.showFocusMode) _buildFocusModeBanner(config),
              if (config.showFocusMode) const SizedBox(height: 12),
              _buildContentBody(content, config),
              if (_showChecklist && config.showChecklist)
                _buildChecklistSection(content, config),
              const SizedBox(height: 24),
              if (content.quizOptions.isNotEmpty)
                _buildQuizSection(content, config),
              if (content.flashcards.isNotEmpty && config.showFlashcards)
                _buildFlashcardPreview(content.flashcards),
              if (config.showReminders) _buildReminderBanner(config),
              const SizedBox(height: 24),
              _buildNavigationButtons(content, config),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentHeader(ContentItem content, LearningProfileConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getModeColor(content.contentType).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content.difficulty,
            style: TextStyle(
              color: _getModeColor(content.contentType),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        if (content.tags.isNotEmpty && config.showTags) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: content.tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileSelector(LearningProfileConfig activeConfig) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: LearningAccessibilityProfile.values.map((profile) {
          final config = getProfileConfig(profile);
          final isSelected = profile == _activeProfile;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(config.label, style: const TextStyle(fontSize: 12)),
              avatar: Icon(config.icon, size: 16),
              onSelected: (_) {
                setState(() {
                  _activeProfile = profile;
                  final newConfig = getProfileConfig(profile);
                  _showPreview = newConfig.showSessionPreview;
                  if (newConfig.autoSimplify) {
                    _simplifyContent(context.read<SessionState>().currentContent ?? _contentLibrary.first);
                  } else {
                    _useSimplified = false;
                    _simplifiedBody = null;
                    _simplifiedForContentId = null;
                  }
                  if (newConfig.showPauseControls) _showPause = false;
                  if (newConfig.showChecklist && _contentLibrary.isNotEmpty) {
                    _initChecklist(_contentLibrary.first);
                  } else if (!newConfig.showChecklist) {
                    _showChecklist = false;
                    _checklistItems = [];
                    _taskStep = 0;
                  }
                  if (newConfig.chunkedReading && _contentLibrary.isNotEmpty) {
                    _initReadingChunks(_contentLibrary.first);
                  } else {
                    _readingChunks = [];
                    _currentChunk = 0;
                  }
                  if (newConfig.scaffoldedRelease) {
                    _scaffoldStage = 0;
                  }
                  if (newConfig.scaffoldHints) {
                    _hintsRevealed = false;
                    _hintLevel = 0;
                  }
                  if (newConfig.showFocusMode) {
                    _focusTimerActive = false;
                  }
                  _templateIndex = 0;
                });
              },
              selectedColor: config.color.withValues(alpha: 0.2),
              checkmarkColor: config.color,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentBody(ContentItem content, LearningProfileConfig config) {
    final displayText = _useSimplified && _simplifiedBody != null
        ? _simplifiedBody!
        : content.body;

    if (config.stepByStep && _steps.isNotEmpty && !config.scaffoldedRelease) {
      return _buildStepBody(content, displayText, config);
    }

    if (config.scaffoldedRelease) {
      return _buildScaffoldedReleaseBody(content, displayText, config);
    }

    if (config.chunkedReading && _readingChunks.isNotEmpty) {
      return _buildChunkedReadingBody(content, displayText, config);
    }

    return _buildStandardContentBody(content, displayText, config);
  }

  Widget _buildStandardContentBody(
      ContentItem content, String displayText, LearningProfileConfig config) {
    final bgColor = config.calmColors
        ? AppColors.calmBg.withValues(alpha: 0.4)
        : AppColors.cardLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.visualMathBar) _buildVisualMathBar(),
          if (config.visualMathBar) const SizedBox(height: 12),
          if (config.showWorkedExamples)
            _buildWorkedExample(content, config, displayText),
          if (config.showWorkedExamples && displayText.isNotEmpty)
            const SizedBox(height: 16),
          if (config.scaffoldHints) ...[
            _buildScaffoldedHints(content, config),
            const SizedBox(height: 12),
          ],
          if (!config.autoSimplify)
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    if (_useSimplified) {
                      setState(() {
                        _useSimplified = false;
                        _simplifiedBody = null;
                      });
                    } else {
                      _simplifyContent(content);
                    }
                  },
                  icon: Icon(
                    _useSimplified ? Icons.auto_stories : Icons.psychology,
                    size: 18,
                  ),
                  label: Text(_useSimplified ? 'Original' : 'Simplify'),
                ),
              ],
            ),
          if (config.showSectionLabels)
            _buildSectionLabel('Lesson Content'),
          if (config.showSectionLabels) const SizedBox(height: 8),
          if (config.showProgressBar)
            _buildProgressBar(config),
          if (config.showProgressBar) const SizedBox(height: 12),
          Text(
            displayText,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: config.fontFamily,
              fontSize: 16 * (config.calmColors ? 1.0 : 1.0),
              height: config.lineHeight,
              letterSpacing: config.letterSpacing,
              color: config.calmColors
                  ? AppColors.textPrimary.withValues(alpha: 0.85)
                  : null,
            ),
          ),
          if (_useSimplified) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.softGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Simplified version',
                style: TextStyle(
                  color: AppColors.softGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (config.showReadAloud) ...[
            const SizedBox(height: 16),
            _buildReadAloudButton(displayText, config),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sereneBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.sereneBlue,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProgressBar(LearningProfileConfig config) {
    final sessionState = context.watch<SessionState>();
    final total = sessionState.activeContent.length;
    final current = sessionState.activeContentIndex + 1;
    final progress = total > 0 ? current / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lesson $current of $total',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
              config.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepBody(ContentItem content, String displayText, LearningProfileConfig config) {
    final steps = _steps;
    final current = _currentStep.clamp(0, steps.length - 1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.softPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Step ${current + 1} of ${steps.length}',
                  style: const TextStyle(
                    color: AppColors.softPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                current == 0 ? Icons.looks_one : Icons.arrow_upward,
                size: 16,
                color: AppColors.softPurple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            steps[current],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                ),
          ),
          if (steps.length > 1) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (current > 0)
                  Semantics(
                    button: true,
                    label: 'Previous step',
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _currentStep = current - 1),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (current < steps.length - 1)
                  Semantics(
                    button: true,
                    label: 'Next step',
                    child: FilledButton.icon(
                      onPressed: () =>
                          setState(() => _currentStep = current + 1),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Next'),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _initReadingChunks(ContentItem content) {
    final text = _useSimplified && _simplifiedBody != null ? _simplifiedBody! : content.body;
    _readingChunks = text
        .split(RegExp(r'\n\n+'))
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.trim())
        .toList();
    _currentChunk = 0;
  }

  Widget _buildChunkedReadingBody(
      ContentItem content, String displayText, LearningProfileConfig config) {
    if (_readingChunks.isEmpty) _initReadingChunks(content);
    if (_readingChunks.isEmpty) {
      return _buildStandardContentBody(content, displayText, config);
    }
    final chunk = _currentChunk.clamp(0, _readingChunks.length - 1);
    final chunkText = _readingChunks[chunk];
    final chunkColors = [
      const Color(0xFF7B68EE),
      const Color(0xFF2A9D8F),
      const Color(0xFFE76F51),
      const Color(0xFF457B9D),
      const Color(0xFFE9C46A),
      const Color(0xFF52B788),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.showProgressIndication)
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.softPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Part ${chunk + 1} of ${_readingChunks.length}',
                    style: const TextStyle(
                      color: AppColors.softPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (config.showReadAloud)
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined, size: 20),
                    tooltip: 'Read aloud',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reading aloud...'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
              ],
            ),
          if (config.showProgressIndication) const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: chunkColors[chunk % chunkColors.length]
                    .withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.multisensoryCues)
                  Container(
                    width: 4,
                    height: 24,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: chunkColors[chunk % chunkColors.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Text(
                  chunkText,
                  style: TextStyle(
                    fontFamily: config.fontFamily,
                    fontSize: 16,
                    height: config.lineHeight,
                    letterSpacing: config.letterSpacing,
                  ),
                ),
              ],
            ),
          ),
          if (_readingChunks.length > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (chunk > 0)
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _currentChunk = chunk - 1),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                if (chunk < _readingChunks.length - 1)
                  FilledButton.icon(
                    onPressed: () =>
                        setState(() => _currentChunk = chunk + 1),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Next'),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadAloudButton(String text, LearningProfileConfig config) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reading ${text.length} characters aloud...'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      icon: const Icon(Icons.volume_up_outlined, size: 18),
      label: const Text('Read Aloud'),
    );
  }

  Widget _buildVisualMathBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.calmTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.calmTeal.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded,
                  size: 14, color: AppColors.calmTeal),
              const SizedBox(width: 6),
              Text(
                'Number Reference',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.calmTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(11, (i) {
              return Column(
                children: [
                  Container(
                    width: 20,
                    height: 20 * (i / 10 + 0.2),
                    decoration: BoxDecoration(
                      color: AppColors.calmTeal.withValues(
                        alpha: 0.3 + (i / 10) * 0.5,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$i',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 40,
                height: 3,
                color: AppColors.calmTeal.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              const Text(
                '= 1 unit',
                style: TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
              ),
              const Spacer(),
              const Text(
                '■■ = 2  ■■■ = 3',
                style: TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkedExample(
      ContentItem content, LearningProfileConfig config, String displayText) {
    final paragraphs =
        displayText.split(RegExp(r'\n\n+')).where((p) => p.trim().isNotEmpty).toList();
    final example = paragraphs.isNotEmpty ? paragraphs.first : displayText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Worked Example',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (config.scaffoldHints)
                TextButton(
                  onPressed: () =>
                      setState(() => _hintsRevealed = !_hintsRevealed),
                  child: Text(
                    _hintsRevealed ? 'Hide hints' : 'Show hints',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            example.length > 120 ? '${example.substring(0, 120)}...' : example,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textPrimary.withValues(alpha: 0.85),
            ),
          ),
          if (_hintsRevealed) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How this works:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. Read the main point above\n'
                    '2. Notice how each idea connects\n'
                    '3. Try to explain it in your own words',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScaffoldedHints(
      ContentItem content, LearningProfileConfig config) {
    final hints = [
      'Think about the main idea of this section.',
      'Look for keywords that tell you what is important.',
      'Try to connect this to something you already know.',
      'Can you explain this in one sentence?',
    ];
    final visibleHints = hints.take(_hintLevel + 1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline,
                size: 16, color: AppColors.softGold),
            const SizedBox(width: 6),
            Text(
              'Hints',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.softGold,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_hintLevel < hints.length - 1) {
                    _hintLevel++;
                  }
                });
              },
              child: Text(
                _hintLevel < hints.length - 1
                    ? 'Show next hint'
                    : 'All hints shown',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        ...visibleHints.map((hint) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.softGold)),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScaffoldedReleaseBody(ContentItem content, String displayText,
      LearningProfileConfig config) {
    final paragraphs = displayText
        .split(RegExp(r'\n\n+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (paragraphs.isEmpty) {
      return _buildStandardContentBody(content, displayText, config);
    }

    final iDoCount = (paragraphs.length * 0.25).ceil().clamp(1, paragraphs.length);
    final weDoCount = (paragraphs.length * 0.35).ceil();
    final iDoParagraphs = paragraphs.take(iDoCount).toList();
    final weDoParagraphs = paragraphs.skip(iDoCount).take(weDoCount).toList();
    final youDoParagraphs = paragraphs.skip(iDoCount + weDoCount).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.showProgressBar) _buildProgressBar(config),
          if (config.showProgressBar) const SizedBox(height: 16),
          if (config.showSectionLabels) ...[
            _buildSectionLabel('Scaffolded Lesson'),
            const SizedBox(height: 12),
          ],
          _buildScaffoldStageBanner(
            _scaffoldStage == 0
                ? 'I Do'
                : _scaffoldStage == 1
                    ? 'We Do'
                    : 'You Do',
            _scaffoldStage == 0
                ? 'Watch and follow along'
                : _scaffoldStage == 1
                    ? 'Let us work through this together'
                    : 'Now try on your own',
            _scaffoldStage == 0
                ? AppColors.softPurple
                : _scaffoldStage == 1
                    ? AppColors.calmTeal
                    : AppColors.success,
          ),
          const SizedBox(height: 16),
          if (_scaffoldStage == 0)
            ...iDoParagraphs.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('→ ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.softPurple)),
                      Expanded(
                        child: Text(
                          p,
                          style: TextStyle(
                            height: config.lineHeight,
                            fontFamily: config.fontFamily,
                            letterSpacing: config.letterSpacing,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          if (_scaffoldStage == 1)
            ...weDoParagraphs.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.calmTeal.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.calmTeal.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p,
                              style: TextStyle(
                                height: config.lineHeight,
                                fontFamily: config.fontFamily,
                                letterSpacing: config.letterSpacing,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.calmTeal.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.help_outline,
                                      size: 14, color: AppColors.calmTeal),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'What do you notice about this part?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.calmTeal,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          if (_scaffoldStage == 2)
            ...youDoParagraphs.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Checkbox(
                        value: false,
                        onChanged: null,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p,
                          style: TextStyle(
                            height: config.lineHeight,
                            fontFamily: config.fontFamily,
                            letterSpacing: config.letterSpacing,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_scaffoldStage > 0)
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _scaffoldStage = _scaffoldStage - 1),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(_scaffoldStage == 1 ? 'Back to I Do' : 'Back to We Do'),
                )
              else
                const SizedBox.shrink(),
              if (_scaffoldStage < 2)
                FilledButton.icon(
                  onPressed: () =>
                      setState(() => _scaffoldStage = _scaffoldStage + 1),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(
                      _scaffoldStage == 0 ? 'Start We Do' : 'Start You Do'),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScaffoldStageBanner(
      String stage, String instruction, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              stage,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWritingTemplateQuiz(ContentItem content, LearningProfileConfig config) {
    final templates = [
      {
        'title': 'Summary Template',
        'prompt': 'The main topic of this lesson is __________. '
            'One important fact is __________. '
            'This connects to __________ because __________.',
      },
      {
        'title': 'Question & Answer',
        'prompt': 'Question: __________\n'
            'My answer: __________\n'
            'Evidence from the lesson: __________',
      },
      {
        'title': 'Key Ideas',
        'prompt': 'Three things I learned:\n'
            '1. __________\n'
            '2. __________\n'
            '3. __________\n'
            'One thing I want to know more about: __________',
      },
    ];

    final template = templates[_templateIndex.clamp(0, templates.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Check',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.description_outlined, size: 16, color: AppColors.softGold),
            const SizedBox(width: 6),
            Text(
              template['title'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.softGold,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: _templateIndex > 0
                      ? () => setState(() => _templateIndex--)
                      : null,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  '${_templateIndex + 1}/${templates.length}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: _templateIndex < templates.length - 1
                      ? () => setState(() => _templateIndex++)
                      : null,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softGold.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.softGold.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            template['prompt'] ?? '',
            style: const TextStyle(
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _answerController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Fill in the blanks or write your answer...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: config.showSpeechToText
                ? _buildSpeechButton()
                : null,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            final answer = _answerController.text.trim();
            if (answer.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill in the template first'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            _recordInteraction(
              context,
              content,
              'completed',
              wasSuccessful: true,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Answer submitted!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            _answerController.clear();
          },
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildQuizSection(ContentItem content, LearningProfileConfig config) {
    if (config.showWritingTemplates) {
      return _buildWritingTemplateQuiz(content, config);
    }
    if (config.useTextInputInsteadOfChoices) {
      return _buildTextInputQuiz(content, config);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Check',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...content.quizOptions.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              button: true,
              label: 'Answer: ${entry.value}',
              child: OutlinedButton(
                onPressed: () {
                  final correct = entry.key == content.correctOptionIndex;
                  _recordInteraction(
                    context,
                    content,
                    correct ? 'completed' : 'struggled',
                    wasSuccessful: correct,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          correct ? 'Correct!' : 'Not quite, try again!'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(entry.value),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextInputQuiz(ContentItem content, LearningProfileConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Check',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Type your answer below',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        if (config.showSentenceStarters) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _sentenceStarters.map((starter) {
              return ActionChip(
                label: Text(starter, style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  final existing = _answerController.text;
                  if (existing.isNotEmpty && !existing.endsWith(' ')) {
                    _answerController.text = '$existing ';
                  }
                  _answerController.text = '${_answerController.text}$starter ';
                  _answerController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _answerController.text.length),
                  );
                },
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _answerController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: config.showSentenceStarters
                ? 'Pick a starter above or type your own...'
                : 'Type your answer here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: config.showSpeechToText
                ? _buildSpeechButton()
                : null,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            final answer = _answerController.text.trim();
            if (answer.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please type an answer first'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            _recordInteraction(
              context,
              content,
              'completed',
              wasSuccessful: true,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Answer submitted!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            _answerController.clear();
          },
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text('Submit'),
        ),
        if (config.showWordPrediction) ...[
          const SizedBox(height: 12),
          Text(
            'Word suggestions: ${_getWordSuggestions(content)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ],
    );
  }

  String _getWordSuggestions(ContentItem content) {
    final all = [content.title, content.description, ...content.tags, ...content.quizOptions];
    final words = all.expand((s) => s.split(RegExp(r'\s+'))).where((w) => w.length > 3).toSet().toList();
    words.shuffle();
    return words.take(5).join(', ');
  }

  Widget _buildFlashcardPreview(List<ContentItem> flashcards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Flashcards in this lesson',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...flashcards.map((fc) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softPurple.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.softPurple.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.style_outlined, color: AppColors.softPurple, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fc.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        fc.body,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChecklistSection(ContentItem content, LearningProfileConfig config) {
    if (_checklistItems.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sereneBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sereneBlue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, size: 20, color: AppColors.sereneBlue),
              const SizedBox(width: 8),
              Text(
                'Progress Checklist',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.sereneBlue,
                    ),
              ),
              const Spacer(),
              Text(
                '${_checklistItems.where((e) => e).length}/${_checklistItems.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.sereneBlue,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._checklistItems.asMap().entries.map((entry) {
            final index = entry.key;
            final done = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: done,
                      onChanged: (val) {
                        setState(() {
                          _checklistItems[index] = val ?? false;
                          if (val == true) {
                            _taskStep = (_taskStep + 1).clamp(0, _checklistItems.length - 1);
                          }
                        });
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      config.showNextStepProminent && index == _taskStep
                          ? '→ ${_getParagraphPreview(content, index)}'
                          : _getParagraphPreview(content, index),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: done
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration: done ? TextDecoration.lineThrough : null,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getParagraphPreview(ContentItem content, int index) {
    final paragraphs = content.body.split(RegExp(r'\n\n+')).where((p) => p.trim().isNotEmpty).toList();
    if (index >= paragraphs.length) return '';
    final text = paragraphs[index].trim();
    final words = text.split(' ');
    if (words.length <= 10) return text;
    return '${words.take(10).join(' ')}...';
  }

  Widget _buildSpeechButton() {
    return IconButton(
      icon: Icon(_isListening ? Icons.mic : Icons.mic_outlined),
      tooltip: _isListening ? 'Tap to stop' : 'Use speech-to-text',
      color: _isListening ? AppColors.warmCoral : null,
      onPressed: () {
        if (_isListening) {
          _speechService.stopListening();
          setState(() => _isListening = false);
          return;
        }
        _speechService.initialize().then((_) {
          if (!_speechService.isAvailable) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Speech not available on this device'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
          if (!mounted) return;
          setState(() => _isListening = true);
          _speechService.startListening(
            onPartialResult: (text) {
              if (!mounted) return;
              debugPrint('STT partial: "$text"');
              _answerController.text = text;
              _answerController.selection = TextSelection.fromPosition(
                TextPosition(offset: text.length),
              );
              setState(() {});
            },
            onResult: (text) {
              if (!mounted) return;
              debugPrint('STT final: "$text"');
              _answerController.text = text;
              _answerController.selection = TextSelection.fromPosition(
                TextPosition(offset: text.length),
              );
              setState(() {});
            },
            onError: (error) {
              debugPrint('STT error: $error');
            },
          );
        });
      },
    );
  }

  Widget _buildFocusModeBanner(LearningProfileConfig config) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warmCoral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warmCoral.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_outlined,
              size: 18, color: AppColors.warmCoral),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _focusTimerActive
                  ? 'Focus mode active — keep going!'
                  : 'Focus mode: one section at a time',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.warmCoral,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                setState(() => _focusTimerActive = !_focusTimerActive),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _focusTimerActive ? 'Pause' : 'Start',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderBanner(LearningProfileConfig config) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.softGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 18, color: AppColors.softGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              config.profile == LearningAccessibilityProfile.adhd
                  ? 'Stay focused on this section. Take a break when you finish.'
                  : 'Keep going — you are making progress.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.softGold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ContentItem content, LearningProfileConfig config) {
    final sessionState = context.watch<SessionState>();
    final hasPrev = sessionState.activeContentIndex > 0;
    final hasNext = sessionState.activeContentIndex < sessionState.activeContent.length - 1;

    if (config.showOneActionAtATime) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasNext)
            FilledButton.icon(
              onPressed: () {
                sessionState.advanceContent();
                if (config.autoSimplify) {
                  _simplifyContent(_contentLibrary[
                      sessionState.activeContentIndex.clamp(0, _contentLibrary.length - 1)]);
                } else {
                  _useSimplified = false;
                  _simplifiedBody = null;
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Next Lesson'),
            )
          else
            FilledButton.icon(
              onPressed: () {
                _recordInteraction(context, content, 'completed', wasSuccessful: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Great progress!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Complete'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (hasPrev)
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Previous lesson',
                  child: OutlinedButton.icon(
                    onPressed: () {
                      sessionState.goBackContent();
                      if (config.autoSimplify) {
                        _simplifyContent(_contentLibrary[
                            sessionState.activeContentIndex.clamp(0, _contentLibrary.length - 1)]);
                      } else {
                        _useSimplified = false;
                        _simplifiedBody = null;
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Previous'),
                  ),
                ),
              ),
            if (hasPrev) const SizedBox(width: 12),
            if (hasNext)
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Next lesson',
                  child: FilledButton.icon(
                    onPressed: () {
                      sessionState.advanceContent();
                      if (config.autoSimplify) {
                        _simplifyContent(_contentLibrary[
                            sessionState.activeContentIndex.clamp(0, _contentLibrary.length - 1)]);
                      } else {
                        _useSimplified = false;
                        _simplifiedBody = null;
                      }
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Next'),
                  ),
                ),
              ),
            if (!hasPrev && !hasNext) const Spacer(),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: 'Mark as complete',
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                _recordInteraction(context, content, 'completed', wasSuccessful: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Great progress!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Complete'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewScreen(BuildContext context, ContentItem content, LearnerProfile profile) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What to Expect'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.sereneBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.visibility_outlined,
                    color: AppColors.sereneBlue, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                'Here is what you will learn',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewRow('Lesson', content.title),
                    const SizedBox(height: 12),
                    _buildPreviewRow('Difficulty', content.difficulty),
                    const SizedBox(height: 12),
                    _buildPreviewRow('Content', content.contentType.replaceAll('_', ' ')),
                    if (content.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildPreviewRow('Topics', content.tags.join(', ')),
                    ],
                    const SizedBox(height: 12),
                    _buildPreviewRow('Description', content.description),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.calmTeal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.loop_rounded,
                        size: 16, color: AppColors.calmTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Work through this lesson step by step at your own pace.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.calmTeal,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => setState(() => _showPreview = false),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Lesson'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPauseOverlay(BuildContext context, SessionState sessionState) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Paused'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.calmTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.spa_outlined,
                      color: AppColors.calmTeal, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'Take a break',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'There is no rush. Come back whenever you feel ready.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: () => setState(() => _showPause = false),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume Session'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => setState(() => _showSummary = true),
                  icon: const Icon(Icons.stop_outlined),
                  label: const Text('End Session'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryScreen(
      BuildContext context, SessionState sessionState) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Summary'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: AppColors.success,
              ),
              const SizedBox(height: 24),
              Text(
                'Session Complete',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'You engaged with ${_contentLibrary.length} lessons.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Keep up the great work!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LearningAccessibilityProfile _traitsToProfile(List<String> traits) {
    if (traits.contains('dyslexia')) return LearningAccessibilityProfile.dyslexia;
    if (traits.contains('adhd')) return LearningAccessibilityProfile.adhd;
    if (traits.contains('dysgraphia')) return LearningAccessibilityProfile.dysgraphia;
    if (traits.contains('dyscalculia')) return LearningAccessibilityProfile.dyscalculia;
    if (traits.contains('autism')) return LearningAccessibilityProfile.autism;
    if (traits.contains('sensory processing')) return LearningAccessibilityProfile.sensoryProcessing;
    if (traits.contains('executive dysfunction')) return LearningAccessibilityProfile.executiveDysfunction;
    return LearningAccessibilityProfile.none;
  }

  void _initChecklist(ContentItem content) {
    final paragraphs = content.body.split(RegExp(r'\n\n+')).where((p) => p.trim().isNotEmpty).toList();
    _checklistItems = List.filled(paragraphs.length, false);
    _taskStep = 0;
    _showChecklist = true;
  }

  void _simplifyContent(ContentItem content) {
    final simplified = content.simplifiedVersion.isNotEmpty
        ? content.simplifiedVersion
        : content.body;
    setState(() {
      _useSimplified = true;
      _simplifiedBody = simplified;
    });
  }

  void _recordInteraction(
    BuildContext context,
    ContentItem content,
    String type, {
    bool wasSuccessful = true,
  }) {
    final learnerState = context.read<LearnerState>();
    final sessionState = context.read<SessionState>();
    final appState = context.read<AppState>();

    if (!sessionState.isInSession) {
      sessionState.startSession(learnerState.profile.id,
          type: content.contentType);
    }

    sessionState.recordInteraction(
      InteractionEvent(
        id: UniqueKey().toString(),
        sessionId: sessionState.currentSession?.id ?? '',
        learnerId: learnerState.profile.id,
        contentType: content.contentType,
        contentId: content.id,
        interactionType: type,
        wasSuccessful: wasSuccessful,
      ),
    );

    appState.processInteraction(
      profile: learnerState.profile,
      contentType: content.contentType,
      interactionType: type,
      wasSuccessful: wasSuccessful,
    ).then((updated) {
      if (!mounted) return;
      learnerState.setProfile(updated);
    });
  }

  Color _getModeColor(String contentType) {
    switch (contentType) {
      case 'quiz':
        return AppColors.warmCoral;
      case 'video':
        return AppColors.sereneBlue;
      case 'flashcard':
        return AppColors.softPurple;
      case 'guided_practice':
        return AppColors.softGold;
      case 'micro_lesson':
        return AppColors.calmTeal;
      case 'visual_summary':
        return AppColors.gentlePink;
      default:
        return AppColors.calmTeal;
    }
  }
}
