import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme/colors.dart';
import '../../state/learner_state.dart';
import '../../state/app_state.dart';
import '../../state/session_state.dart';
import '../../models/learner_profile.dart';
import '../../models/subject_data.dart';
import '../../services/content/content_repository.dart';
import '../../services/study_navigation.dart';
import '../../services/accessibility_service.dart';
import '../video/video_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final learnerState = context.watch<LearnerState>();
    final appState = context.watch<AppState>();
    final sessionState = context.watch<SessionState>();
    final profile = learnerState.profile;
    final hasSessions = sessionState.sessions.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context, profile),
              const SizedBox(height: 24),
              _buildGreeting(context, profile),
              const SizedBox(height: 16),
              _buildHeroSection(context, hasSessions, profile),
              const SizedBox(height: 36),
              _buildSubjectsSection(context),
              const SizedBox(height: 24),
              _buildModesSection(context, appState, profile),
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
        Text(
          'ClarityCrew',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Semantics(
          button: true,
          label: 'Settings',
          child: IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context, LearnerProfile profile) {
    return Text(
      profile.name.isNotEmpty ? 'Hi ${profile.name}' : 'Hi there',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildHeroSection(
      BuildContext context, bool hasSessions, LearnerProfile profile) {
    final appState = context.watch<AppState>();
    final simplifyVisuals = appState.shouldSimplifyVisuals(profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            'School and college topics, made clear.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
          ),
          if (!simplifyVisuals) ...[
            const SizedBox(height: 12),
            Text(
              'Lessons, quizzes, and videos built for neurodivergent learners. '
              'Pick a subject and start at your own pace.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ],
        const SizedBox(height: 24),
        Semantics(
          button: true,
          label: hasSessions ? 'Continue your lessons' : 'Start a lesson',
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: AppColors.calmTeal,
              ),
              onPressed: () => _handlePrimaryAction(context, hasSessions),
              child: Text(
                hasSessions ? 'Continue your lessons' : 'Start a lesson',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        if (!simplifyVisuals) ...[
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Pick a subject below, or choose a learning mode.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  void _handlePrimaryAction(BuildContext context, bool hasSessions) {
    if (hasSessions) {
      final sessionState = context.read<SessionState>();
      final lastSession = sessionState.sessions.last;
      final mode = LearningMode.values.where(
        (m) => m.name.replaceAll('_', '') ==
            lastSession.sessionType.replaceAll('_', ''),
      ).toList();
      StudyNavigation.launchMode(
        context,
        mode.isNotEmpty ? mode.first : LearningMode.microLesson,
      );
      return;
    }
    final subjects = ContentRepository.getSubjects();
    if (subjects.isNotEmpty) {
      _showSubjectContent(context, subjects.first);
    }
  }

  Widget _buildSubjectsSection(BuildContext context) {
    final subjects = ContentRepository.getSubjects();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subjects',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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

  Widget _buildModesSection(
      BuildContext context, AppState appState, LearnerProfile profile) {
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
          'Learning modes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final mode = modes[index];
              return Semantics(
                button: true,
                label: 'Start ${mode.title}',
                child: ActionChip(
                  avatar: Icon(mode.icon, size: 18, color: mode.color),
                  label: Text(mode.title),
                  onPressed: () =>
                      StudyNavigation.launchMode(context, mode.mode),
                  backgroundColor: mode.color.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: mode.color.withValues(alpha: 0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
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
                            subtitle: Text(
                                '${lesson.difficulty} · ${lesson.chapter}'),
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
                            subtitle:
                                Text('${video.duration} · ${video.difficulty}'),
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
}

class _ModeInfo {
  final String title;
  final IconData icon;
  final Color color;
  final LearningMode mode;
  const _ModeInfo(this.title, this.icon, this.color, this.mode);
}
