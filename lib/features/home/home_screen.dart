import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme/colors.dart';
import '../../state/learner_state.dart';
import '../../state/app_state.dart';
import '../../state/session_state.dart';
import '../../models/learner_profile.dart';
import '../../models/learning_recommendation.dart';
import '../../models/subject_data.dart';
import '../../services/content/content_repository.dart';
import '../../services/study_navigation.dart';
import '../../services/accessibility_service.dart';
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
              if (profile.neurodivergentTraits.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPersonalizationSection(context, profile),
              ],
              if (rec != null &&
                  !appState.shouldReduceChoices(profile))
                _buildRecommendedCard(context, rec),
              if (appState.shouldShowContinuePrompt(profile) &&
                  sessionState.sessions.isNotEmpty)
                _buildContinueCard(context, sessionState),
              const SizedBox(height: 24),
              _buildModeGrid(context, appState, profile),
              const SizedBox(height: 28),
              _buildSubjectsSection(context),
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
    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.breakpointDesktop;
    final appState = context.watch<AppState>();
    final tapSize = appState.tapTargetSize(profile).toDouble();
    final iconSize = isDesktop ? 20.0 : 24.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: isDesktop ? 42 : tapSize,
              height: isDesktop ? 42 : tapSize,
              decoration: BoxDecoration(
                color: AppColors.calmTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.calmTeal,
                size: iconSize,
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
                iconSize: iconSize,
                constraints: BoxConstraints(
                  minWidth: tapSize,
                  minHeight: tapSize,
                ),
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
                iconSize: iconSize,
                constraints: BoxConstraints(
                  minWidth: tapSize,
                  minHeight: tapSize,
                ),
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
                iconSize: iconSize,
                constraints: BoxConstraints(
                  minWidth: tapSize,
                  minHeight: tapSize,
                ),
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
    final appState = context.watch<AppState>();
    final greeting = _getGreeting();
    final simplifyVisuals = appState.shouldSimplifyVisuals(profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting${profile.name.isNotEmpty ? ', ${profile.name}' : ''}',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        if (!simplifyVisuals) ...[
          const SizedBox(height: 4),
          Text(
            _getDailyMessage(profile),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildPersonalizationSection(BuildContext context, LearnerProfile profile) {
    final service = AccessibilityService();
    final badges = service.getPersonalizationBadges(profile);
    final descriptions = service.getPersonalizationDescriptions(profile);
    if (badges.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.calmTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.calmTeal.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_outlined, size: 16, color: AppColors.calmTeal),
              const SizedBox(width: 6),
              Text(
                'Your Personalization',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.calmTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: badges.map((b) {
              final (label, icon, color) = b;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (descriptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...descriptions.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                d,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            )),
          ],
        ],
      ),
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

  Widget _buildRecommendedCard(BuildContext context, LearningRecommendation rec) {
    return Semantics(
      button: true,
      label: 'Recommended: ${rec.title}',
      child: GestureDetector(
        onTap: () => StudyNavigation.launchRecommendation(context, rec),
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

  Widget _buildContinueCard(BuildContext context, SessionState sessionState) {
    final lastSession = sessionState.sessions.last;
    if (lastSession.completed) return const SizedBox.shrink();
    final modes = LearningMode.values.where(
      (m) => m.name.replaceAll('_', '') ==
          lastSession.sessionType.replaceAll('_', ''),
    ).toList();
    final mode = modes.isNotEmpty ? modes.first : LearningMode.microLesson;
    return Semantics(
      button: true,
      label: 'Continue your last session',
      child: GestureDetector(
        onTap: () => StudyNavigation.launchMode(context, mode),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.softGold.withValues(alpha: 0.15),
                AppColors.warmCoral.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.softGold.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: AppColors.softGold, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Continue Where You Left Off',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You have an incomplete ${lastSession.sessionType.replaceAll('_', ' ')} session',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.softGold, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeGrid(BuildContext context, AppState appState, LearnerProfile profile) {
    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.breakpointDesktop;
    final tapSize = appState.tapTargetSize(profile).toDouble();
    final allModes = [
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
    final displayLimit = appState.getModeDisplayLimit(profile);
    final modes = allModes.take(displayLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              displayLimit < allModes.length ? 'Your Best Modes' : 'Learning Modes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (displayLimit < allModes.length) ...[
              const SizedBox(width: 8),
              Icon(Icons.auto_awesome, size: 16, color: AppColors.calmTeal),
            ],
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 2,
            childAspectRatio: isDesktop ? 1.2 : 1.1,
            crossAxisSpacing: isDesktop ? 16 : 12,
            mainAxisSpacing: isDesktop ? 16 : 12,
          ),
          itemCount: modes.length,
          itemBuilder: (context, index) {
            final mode = modes[index];
            return Semantics(
              button: true,
              label: 'Start ${mode.title}',
              child: GestureDetector(
                onTap: () => StudyNavigation.launchMode(context, mode.mode),
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
                        width: tapSize > 48 ? 48 : 40,
                        height: tapSize > 48 ? 48 : 40,
                        decoration: BoxDecoration(
                          color: mode.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(mode.icon, color: mode.color, size: tapSize > 48 ? 26 : 22),
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

  Widget _buildSubjectsSection(BuildContext context) {
    final subjects = ContentRepository.getSubjects();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subjects',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Semantics(
                button: true,
                label: 'Study ${subject.name}',
                child: GestureDetector(
                  onTap: () => _showSubjectContent(context, subject),
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: subject.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: subject.color.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: subject.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(subject.icon,
                                  color: subject.color, size: 20),
                            ),
                            const Spacer(),
                            if (subject.videoCount > 0)
                              Icon(Icons.play_circle_outline,
                                  size: 14,
                                  color: subject.color.withValues(alpha: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subject.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${subject.lessonCount} lesson${subject.lessonCount == 1 ? '' : 's'}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSubjectContent(BuildContext context, SubjectData subject) {
    final lessons = ContentRepository.getBySubject(subject.name);
    final videos = ContentRepository.getVideosForSubject(subject.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.35,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(subject.icon, color: subject.color, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        subject.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subject.chapters.join(' · '),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 20),
                  if (lessons.isNotEmpty) ...[
                    Text(
                      'Lessons',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...lessons.map((lesson) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(lesson.title),
                            subtitle: Text('${lesson.difficulty} · ${lesson.chapter}'),
                            trailing: const Icon(Icons.arrow_forward_rounded),
                            onTap: () {
                              Navigator.pop(context);
                              StudyNavigation.launchMode(
                                context,
                                LearningMode.microLesson,
                                contentId: lesson.id,
                              );
                            },
                          ),
                        )),
                  ],
                  if (videos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Videos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...videos.map((video) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(video.title),
                            subtitle: Text('${video.duration} · ${video.difficulty}'),
                            leading: const Icon(Icons.play_circle_outline,
                                color: AppColors.sereneBlue),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoScreen(
                                    videoId: video.id,
                                    lessonId: video.linkedLessonId,
                                  ),
                                ),
                              );
                            },
                          ),
                        )),
                  ],
                ],
              ),
            );
          },
        );
      },
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
    StudyNavigation.launchMode(context, mode);
  }
}

class _ModeInfo {
  final String title;
  final IconData icon;
  final Color color;
  final LearningMode mode;
  const _ModeInfo(this.title, this.icon, this.color, this.mode);
}
