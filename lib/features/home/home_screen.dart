import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../state/learner_state.dart';
import '../../state/app_state.dart';
import '../../state/session_state.dart';
import '../../models/learner_profile.dart';
import '../focus/focus_mode_screen.dart';
import '../learning/learning_session_screen.dart';
import '../quiz/quiz_screen.dart';
import '../flashcards/flashcard_screen.dart';
import '../video/video_screen.dart';
import '../progress/progress_screen.dart';
import '../settings/settings_screen.dart';
import '../ai_tutor/ai_tutor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final learnerState = context.watch<LearnerState>();
    final appState = context.watch<AppState>();
    final sessionState = context.watch<SessionState>();
    final profile = learnerState.profile;
    final rec = appState.currentRecommendation;
    appState.updateSessionData(sessionState.sessions);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildHeader(context, profile),
              const SizedBox(height: 20),
              _buildGreeting(context, profile),
              const SizedBox(height: 24),
              if (rec != null) _buildRecommendedCard(context, rec),
              const SizedBox(height: 24),
              _buildModeGrid(context),
              const SizedBox(height: 24),
              _buildQuickStats(context, sessionState),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LearnerProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.calmTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.calmTeal,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ClarityCrew',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Learn your way',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Semantics(
              button: true,
              label: 'AI Tutor insights',
              child: IconButton(
                icon: const Icon(Icons.auto_awesome_rounded),
                color: AppColors.calmTeal,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AiTutorScreen(),
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Progress insights',
              child: IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProgressScreen(),
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Settings',
              child: IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context, LearnerProfile profile) {
    final greeting = _getGreeting();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting${profile.name.isNotEmpty ? ', ${profile.name}' : ''}',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 4),
        Text(
          _getDailyMessage(profile),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getDailyMessage(LearnerProfile profile) {
    final mode = profile.modeWeights.entries.isEmpty
        ? 'exploring'
        : profile.modeWeights.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
            .name;
    return 'Ready to learn? Your flow today looks like $mode.';
  }

  Widget _buildRecommendedCard(BuildContext context, dynamic rec) {
    return Semantics(
      button: true,
      label: 'Recommended: ${rec.title}',
      child: GestureDetector(
        onTap: () => _launchMode(context, rec.recommendedMode),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.calmTeal.withValues(alpha: 0.1),
                AppColors.sereneBlue.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.calmTeal.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.calmTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Recommended for you',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.calmTeal,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.calmTeal.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                rec.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                rec.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${rec.estimatedDuration ~/ 60} min',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.trending_up,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${(rec.confidence * 100).round()}% match',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeGrid(BuildContext context) {
    final modes = [
      _ModeInfo('Quiz', Icons.quiz_outlined, AppColors.warmCoral,
          LearningMode.quiz),
      _ModeInfo('Video', Icons.play_circle_outline, AppColors.sereneBlue,
          LearningMode.video),
      _ModeInfo('Flashcards', Icons.style_outlined, AppColors.softPurple,
          LearningMode.flashcard),
      _ModeInfo('Guided Practice', Icons.psychology_outlined,
          AppColors.softGold, LearningMode.guidedPractice),
      _ModeInfo('Micro Lesson', Icons.bolt_outlined, AppColors.calmTeal,
          LearningMode.microLesson),
      _ModeInfo('Visual Summary', Icons.image_outlined, AppColors.gentlePink,
          LearningMode.visualSummary),
      _ModeInfo('Focus Sprint', Icons.timer_outlined, AppColors.success,
          LearningMode.focusSprint),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Modes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: modes.length,
          itemBuilder: (context, index) {
            final mode = modes[index];
            return Semantics(
              button: true,
              label: 'Start ${mode.title}',
              child: GestureDetector(
                onTap: () => _launchMode(context, mode.mode),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: mode.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: mode.color.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: mode.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(mode.icon, color: mode.color, size: 22),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        mode.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, SessionState sessionState) {
    final sessionCount = sessionState.sessions.length;
    final avgEngagement = sessionState.averageEngagement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Sessions',
                '$sessionCount',
                Icons.menu_book_rounded,
                AppColors.calmTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Engagement',
                '${(avgEngagement * 100).round()}%',
                Icons.trending_up_rounded,
                AppColors.warmCoral,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Focus',
                sessionState.isInSession ? 'Active' : 'Ready',
                Icons.timer_outlined,
                AppColors.softPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  void _launchMode(BuildContext context, LearningMode mode) {
    switch (mode) {
      case LearningMode.quiz:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const QuizScreen()));
      case LearningMode.video:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const VideoScreen()));
      case LearningMode.flashcard:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FlashcardScreen()));
      case LearningMode.guidedPractice:
      case LearningMode.microLesson:
      case LearningMode.visualSummary:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const LearningSessionScreen()));
      case LearningMode.focusSprint:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FocusModeScreen()));
    }
  }
}

class _ModeInfo {
  final String title;
  final IconData icon;
  final Color color;
  final LearningMode mode;
  const _ModeInfo(this.title, this.icon, this.color, this.mode);
}
