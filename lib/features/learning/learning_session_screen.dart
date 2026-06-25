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
      context.read<SessionState>().setActiveContent(
            _contentLibrary,
            startContentId: widget.initialLessonId,
          );
      _sessionInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final sessionState = context.watch<SessionState>();
    final content = sessionState.currentContent ??
        _contentLibrary.first;

    if (_showSummary) {
      return _buildSummaryScreen(context, sessionState);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(content.contentType.replaceAll('_', ' ')),
        centerTitle: true,
        actions: [
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
              _buildContentBody(content),
              const SizedBox(height: 24),
              if (content.quizOptions.isNotEmpty)
                _buildQuizSection(content),
              if (content.flashcards.isNotEmpty)
                _buildFlashcardPreview(content.flashcards),
              const SizedBox(height: 24),
              _buildNavigationButtons(content),
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

  Widget _buildContentBody(ContentItem content) {
    final displayText = _useSimplified && _simplifiedBody != null
        ? _simplifiedBody!
        : content.body;
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
                  height: 1.7,
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

  Widget _buildQuizSection(ContentItem content) {
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
                  padding: const EdgeInsets.all(16),
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

  Widget _buildNavigationButtons(ContentItem content) {
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
            ),
          ),
        ),
      ],
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
