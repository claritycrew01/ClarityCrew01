import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../state/learner_state.dart';
import '../../state/session_state.dart';
import '../../state/app_state.dart';
import '../../models/content_item.dart';
import '../../models/interaction_event.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  final _cards = <ContentItem>[];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _initialized = false;
  int _knownCount = 0;
  int _reviewCount = 0;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _initializeCards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _initializeCards() {
    _cards.addAll([
      ContentItem(
        id: 'fc_1',
        title: 'Chunking',
        contentType: 'flashcard',
        body: 'Breaking information into smaller, manageable groups to reduce cognitive load.',
      ),
      ContentItem(
        id: 'fc_2',
        title: 'Visual Note-Taking',
        contentType: 'flashcard',
        body: 'Using drawings, diagrams, and symbols to capture and remember information.',
      ),
      ContentItem(
        id: 'fc_3',
        title: 'Mind Map',
        contentType: 'flashcard',
        body: 'A diagram that organizes information visually around a central concept.',
      ),
      ContentItem(
        id: 'fc_4',
        title: 'Pomodoro Technique',
        contentType: 'flashcard',
        body: 'Working in focused 25-minute intervals followed by 5-minute breaks.',
      ),
      ContentItem(
        id: 'fc_5',
        title: 'Cognitive Load',
        contentType: 'flashcard',
        body: 'The total amount of mental effort being used in working memory.',
      ),
      ContentItem(
        id: 'fc_6',
        title: 'Sketchnoting',
        contentType: 'flashcard',
        body: 'A form of visual note-taking that combines handwriting, drawings, and typography.',
      ),
    ]);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_reviewCount >= _cards.length) {
      return _buildCompleteScreen(context);
    }

    final card = _cards[_currentIndex];
    final remaining = _cards.length - _reviewCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Boost'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProgressBar(remaining),
              const SizedBox(height: 32),
              Expanded(
                child: _buildFlashcard(card),
              ),
              const SizedBox(height: 24),
              if (_isFlipped) _buildActionButtons(card),
              if (!_isFlipped) _buildTapHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int remaining) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_knownCount known',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '$remaining remaining',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _reviewCount / _cards.length,
            minHeight: 6,
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
            color: AppColors.softPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcard(ContentItem card) {
    return Semantics(
      label: _isFlipped ? 'Answer: ${card.body}' : 'Question: ${card.title}',
      child: GestureDetector(
        onTap: () => _flipCard(),
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final isFront = _flipAnimation.value < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimation.value * 3.14159),
              child: isFront ? _buildFront(card) : _buildBack(card),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFront(ContentItem card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.softPurple.withValues(alpha: 0.1),
            AppColors.sereneBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.softPurple.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.softPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.help_outline,
              color: AppColors.softPurple,
              size: 24,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            card.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to reveal answer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(ContentItem card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.calmTeal.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            card.body,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ContentItem card) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Mark as still learning',
            child: OutlinedButton.icon(
              onPressed: () => _nextCard(false),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Review Later'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warmCoral,
                side: const BorderSide(color: AppColors.warmCoral),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Mark as known',
            child: FilledButton.icon(
              onPressed: () => _nextCard(true),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Got It'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTapHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.softPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tap_and_play,
              size: 18, color: AppColors.softPurple),
          const SizedBox(width: 8),
          Text(
            'Tap the card to reveal the answer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.softPurple,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete!'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.celebration_outlined,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'All Done!',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You reviewed $_knownCount cards',
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
      ),
    );
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _nextCard(bool known) {
    if (known) _knownCount++;
    _reviewCount++;
    _recordInteraction(context, _cards[_currentIndex], known);

    if (_reviewCount < _cards.length) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _cards.length;
        _isFlipped = false;
      });
      _flipController.reset();
    } else {
      setState(() {});
    }
  }

  void _recordInteraction(
    BuildContext context,
    ContentItem card,
    bool known,
  ) {
    final learnerState = context.read<LearnerState>();
    final sessionState = context.read<SessionState>();
    final appState = context.read<AppState>();

    if (!sessionState.isInSession) {
      sessionState.startSession(learnerState.profile.id, type: 'flashcard');
    }

    sessionState.recordInteraction(
      InteractionEvent(
        id: UniqueKey().toString(),
        sessionId: sessionState.currentSession?.id ?? '',
        learnerId: learnerState.profile.id,
        contentType: 'flashcard',
        contentId: card.id,
        interactionType: known ? 'completed' : 'struggled',
        wasSuccessful: known,
      ),
    );

    appState.processInteraction(
      profile: learnerState.profile,
      contentType: 'flashcard',
      interactionType: known ? 'completed' : 'struggled',
      wasSuccessful: known,
    ).then((updated) {
      learnerState.setProfile(updated);
    });

    if (_reviewCount >= _cards.length && sessionState.isInSession) {
      sessionState.endSession(
        engagementScore: _knownCount / _cards.length,
        comprehensionScore: _knownCount / _cards.length,
        completed: true,
      );
    }
  }
}
