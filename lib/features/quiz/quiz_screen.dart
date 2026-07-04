import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../state/learner_state.dart';
import '../../state/session_state.dart';
import '../../state/app_state.dart';
import '../../models/content_item.dart';
import '../../models/interaction_event.dart';
import '../../services/content/content_repository.dart';

class QuizScreen extends StatefulWidget {
  final String? initialLessonId;

  const QuizScreen({super.key, this.initialLessonId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  final _questions = <ContentItem>[];
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  bool _isComplete = false;
  bool _initialized = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _generateQuestions();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final lessons = widget.initialLessonId != null
        ? ContentRepository.getAll()
            .where((l) => l.id == widget.initialLessonId)
            .toList()
        : ContentRepository.getAll();
    _questions.addAll(lessons
        .where((lesson) =>
            lesson.quizOptions.isNotEmpty && lesson.correctOptionIndex != null)
        .map((lesson) {
      return ContentItem(
        id: 'q_${lesson.id}',
        title: lesson.title,
        contentType: 'quiz',
        body: lesson.body.length > 100
            ? lesson.body.substring(0, 100) + '...'
            : lesson.body,
        quizOptions: lesson.quizOptions,
        correctOptionIndex: lesson.correctOptionIndex,
      );
    }));
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quick Challenge')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.quiz_outlined, size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No questions for this lesson.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    if (_isComplete) {
      return _buildResultsScreen(context);
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Challenge'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressBar(),
              const SizedBox(height: 24),
              _buildQuestionCard(question),
              const SizedBox(height: 24),
              if (_showResult) _buildResultFeedback(question),
              const SizedBox(height: 24),
              _buildNextButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentIndex + 1} of ${_questions.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '$_score correct',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.calmTeal,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            minHeight: 6,
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
            color: AppColors.calmTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(ContentItem question) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              question.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),
            ...question.quizOptions.asMap().entries.map((entry) {
              final isSelected = _selectedAnswer == entry.key;
              final isCorrect = entry.key == question.correctOptionIndex;
              Color? borderColor;
              Color? bgColor;

              if (_showResult) {
                if (isCorrect) {
                  borderColor = AppColors.success;
                  bgColor = AppColors.success.withValues(alpha: 0.1);
                } else if (isSelected && !isCorrect) {
                  borderColor = AppColors.warmCoral;
                  bgColor = AppColors.warmCoral.withValues(alpha: 0.1);
                }
              } else if (isSelected) {
                borderColor = AppColors.calmTeal;
                bgColor = AppColors.calmTeal.withValues(alpha: 0.08);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Semantics(
                  button: true,
                  label: entry.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: OutlinedButton(
                      onPressed: _showResult
                          ? null
                          : () => _selectAnswer(entry.key, question),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: borderColor != null
                            ? BorderSide(color: borderColor, width: 2)
                            : null,
                        backgroundColor: bgColor,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.value,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: isSelected || _showResult
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                            ),
                            if (_showResult && isCorrect)
                              const Icon(Icons.check_circle,
                                  color: AppColors.success, size: 22),
                            if (_showResult && isSelected && !isCorrect)
                              const Icon(Icons.cancel,
                                  color: AppColors.warmCoral, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResultFeedback(ContentItem question) {
    final isCorrect = _selectedAnswer == question.correctOptionIndex;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warmCoral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.lightbulb_outline,
            color: isCorrect ? AppColors.success : AppColors.warmCoral,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCorrect
                  ? 'Great job! You got it right.'
                  : 'That was close! The correct answer was: ${question.correctOptionIndex != null && question.correctOptionIndex! < question.quizOptions.length ? question.quizOptions[question.correctOptionIndex!] : 'not available'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        label: _showResult ? 'Next question' : 'Submit answer',
        child: FilledButton(
          onPressed: () {
            if (!_showResult) {
              if (_selectedAnswer == null) return;
              setState(() => _showResult = true);
              _recordInteraction(context, _questions[_currentIndex],
                  _selectedAnswer == _questions[_currentIndex].correctOptionIndex
                      ? 'completed'
                      : 'struggled',
                  wasSuccessful:
                      _selectedAnswer == _questions[_currentIndex].correctOptionIndex);
            } else {
              if (_currentIndex < _questions.length - 1) {
                setState(() {
                  _currentIndex++;
                  _selectedAnswer = null;
                  _showResult = false;
                });
              } else {
                setState(() => _isComplete = true);
                _endSession(context);
              }
            }
          },
          child: Text(_showResult ? 'Next' : 'Submit'),
        ),
      ),
    );
  }

  Widget _buildResultsScreen(BuildContext context) {
    final percentage = (_score / _questions.length * 100).round();
    final message = percentage >= 80
        ? 'Outstanding!'
        : percentage >= 60
            ? 'Great effort!'
            : 'Keep practicing!';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getScoreColor(percentage).withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _getScoreColor(percentage),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_score out of ${_questions.length} correct',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Dashboard'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    _score = 0;
                    _selectedAnswer = null;
                    _showResult = false;
                    _isComplete = false;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.calmTeal;
    return AppColors.warmCoral;
  }

  void _selectAnswer(int index, ContentItem question) {
    setState(() => _selectedAnswer = index);
    if (index == question.correctOptionIndex) {
      _score++;
    }
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
      sessionState.startSession(learnerState.profile.id, type: 'quiz');
    }

    sessionState.recordInteraction(
      InteractionEvent(
        id: UniqueKey().toString(),
        sessionId: sessionState.currentSession?.id ?? '',
        learnerId: learnerState.profile.id,
        contentType: 'quiz',
        contentId: content.id,
        interactionType: type,
        wasSuccessful: wasSuccessful,
      ),
    );

    appState.processInteraction(
      profile: learnerState.profile,
      contentType: 'quiz',
      interactionType: type,
      wasSuccessful: wasSuccessful,
    ).then((updated) {
      if (!mounted) return;
      learnerState.setProfile(updated);
    });
  }

  void _endSession(BuildContext context) {
    final sessionState = context.read<SessionState>();
    if (sessionState.isInSession) {
      sessionState.endSession(
        engagementScore: _score / _questions.length,
        comprehensionScore: _score / _questions.length,
        completed: true,
      );
    }
  }
}
