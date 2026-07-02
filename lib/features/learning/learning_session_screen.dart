import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../state/learner_state.dart';
import '../../state/session_state.dart';
import '../../state/app_state.dart';
import '../../models/content_item.dart';
import '../../models/interaction_event.dart';
import '../../services/content/content_repository.dart';

class LearningSessionScreen extends StatefulWidget {
  final String? initialLessonId;

  const LearningSessionScreen({super.key, this.initialLessonId});

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
  bool _hasDyscalculia = false;

  @override
  void initState() {
    super.initState();
    _contentLibrary.addAll(ContentRepository.getAll());
    _isInitialized = true;
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
      if (appState.shouldShowSessionPreview(profile)) {
        _showPreview = true;
      }
      if (appState.shouldSimplifyContent(profile) &&
          _contentLibrary.isNotEmpty) {
        _simplifyContent(_contentLibrary.first);
      }
      if (appState.shouldShowStepByStep(profile) &&
          _contentLibrary.isNotEmpty) {
        _hasDyscalculia = true;
        _steps = appState.splitIntoSteps(_contentLibrary.first.body, profile);
        _currentStep = 0;
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

    if (_showSummary) {
      return _buildSummaryScreen(context, sessionState);
    }

    if (_showPreview) {
      return _buildPreviewScreen(context, content, profile);
    }

    if (_showPause) {
      return _buildPauseOverlay(context, sessionState);
    }

    if (_hasDyscalculia && _contentLibrary.isNotEmpty) {
      _steps = appState.splitIntoSteps(content.body, profile);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(content.contentType.replaceAll('_', ' ')),
        centerTitle: true,
        actions: [
          if (appState.shouldShowPauseControls(profile))
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContentHeader(content),
              const SizedBox(height: 20),
              _buildContentBody(content, profile, appState),
              const SizedBox(height: 24),
              if (content.quizOptions.isNotEmpty)
                _buildQuizSection(content, profile, appState),
              if (content.flashcards.isNotEmpty)
                _buildFlashcardPreview(content.flashcards),
              const SizedBox(height: 24),
              _buildNavigationButtons(content, profile, appState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentHeader(ContentItem content) {
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
        if (content.tags.isNotEmpty) ...[
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

  Widget _buildContentBody(ContentItem content, LearnerProfile profile, AppState appState) {
    final displayText = _useSimplified && _simplifiedBody != null
        ? _simplifiedBody!
        : content.body;

    if (_hasDyscalculia && _steps.isNotEmpty) {
      return _buildStepBody(content, displayText, profile, appState);
    }

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
          Text(
            displayText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: _useSimplified ? 1.7 : 1.7,
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
        ],
      ),
    );
  }

  Widget _buildStepBody(ContentItem content, String displayText, LearnerProfile profile, AppState appState) {
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

  Widget _buildQuizSection(ContentItem content, LearnerProfile profile, AppState appState) {
    final tapHeight = appState.tapTargetSize(profile).toDouble();
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
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: tapHeight > 48 ? 18 : 16,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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

  Widget _buildNavigationButtons(ContentItem content, LearnerProfile profile, AppState appState) {
    final tapHeight = appState.tapTargetSize(profile).toDouble();
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Mark as complete',
            child: FilledButton.icon(
              onPressed: () {
                _recordInteraction(
                  context,
                  content,
                  'completed',
                  wasSuccessful: true,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Great progress!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Complete'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: EdgeInsets.symmetric(vertical: tapHeight > 48 ? 18 : 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Need a simpler version',
            child: OutlinedButton.icon(
              onPressed: () {
                _simplifyContent(content);
                _recordInteraction(
                  context,
                  content,
                  'requestedSimpler',
                );
              },
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Simplify'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: tapHeight > 48 ? 18 : 12),
              ),
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
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _simplifyContent(ContentItem content) {
    final sentences = content.body.split(RegExp(r'(?<=[.!?])\s+'));
    String simplified;
    if (sentences.length <= 2) {
      simplified = content.body;
    } else {
      simplified = sentences.take(2).join(' ');
      final keyPoints = content.tags.isNotEmpty
          ? '\n\nKey points: ${content.tags.take(3).join(', ')}'
          : '';
      simplified += keyPoints;
    }
    setState(() {
      _useSimplified = true;
      _simplifiedBody = simplified;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Showing simplified version'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Original',
          onPressed: () {
            setState(() {
              _useSimplified = false;
              _simplifiedBody = null;
            });
          },
        ),
      ),
    );
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
