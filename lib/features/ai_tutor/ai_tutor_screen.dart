import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme/colors.dart';
import '../../state/learner_state.dart';
import '../../state/session_state.dart';
import '../../state/app_state.dart';
import '../../models/learner_profile.dart';
import '../../models/learning_recommendation.dart';
import '../../models/tutor_message.dart';
import '../../persistence/tutor_storage.dart';
import '../../services/study_navigation.dart';
import '../../services/tutor/tutor_service.dart';
import '../learning/learning_session_screen.dart';
import '../quiz/quiz_screen.dart';
import '../flashcards/flashcard_screen.dart';
import '../video/video_screen.dart';
import '../focus/focus_mode_screen.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final _messageController = TextEditingController();
  final _tutorService = TutorService();
  final _tutorStorage = TutorStorage();
  final _messages = <TutorMessage>[];
  String? _activeContentId;
  bool _conversationLoaded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    final conversation = await _tutorStorage.loadConversation();
    if (!mounted) return;
    setState(() {
      _messages.addAll(conversation.messages);
      _activeContentId = conversation.lastContentId;
      _conversationLoaded = true;
      if (_messages.isEmpty) {
        _messages.add(
          TutorMessage(
            id: 'welcome',
            role: 'tutor',
            text:
                'I am your AI tutor. Ask me to explain a lesson, simplify a topic, go deeper, or tell you what to study next.',
            timestamp: DateTime.now(),
          ),
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final learnerState = context.read<LearnerState>();
    final appState = context.read<AppState>();
    final userMessage = TutorMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: text,
      contentId: _activeContentId,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
    });
    _messageController.clear();

    final response = _tutorService.respond(
      userMessage: text,
      profile: learnerState.profile,
      contentId: _activeContentId,
      activeRecommendation: appState.currentRecommendation,
    );

    setState(() {
      _messages.add(response);
      _activeContentId = response.contentId ?? _activeContentId;
    });

    await _tutorStorage.saveConversation(
      TutorConversation(
        messages: _messages,
        lastContentId: _activeContentId,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final learnerState = context.watch<LearnerState>();
    final sessionState = context.watch<SessionState>();
    final appState = context.watch<AppState>();
    final profile = learnerState.profile;

    appState.updateSessionData(sessionState.sessions);
    if (appState.recommendations.isEmpty) {
      appState.generateNewRecommendations(profile);
    }
    final recs = appState.recommendations;

    if (!_conversationLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAiHeader(context, profile),
              const SizedBox(height: 24),
              _buildConversation(context),
              const SizedBox(height: 24),
              _buildRecommendedForYou(context, recs, profile),
              const SizedBox(height: 24),
              _buildLearningStyleInsights(context, profile),
              const SizedBox(height: 24),
              _buildQuickActions(context, appState, recs),
              const SizedBox(height: 24),
              _buildSessionHistoryInsight(context, sessionState),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiHeader(BuildContext context, LearnerProfile profile) {
    final bestMode = profile.modeWeights.entries.isEmpty
        ? null
        : profile.modeWeights.entries
            .reduce((a, b) => a.value > b.value ? a : b);

    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.breakpointDesktop;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(isDesktop ? 20 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.calmTeal.withValues(alpha: 0.15),
                AppColors.sereneBlue.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.calmTeal.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isDesktop ? 48 : 56,
                height: isDesktop ? 48 : 56,
                decoration: BoxDecoration(
                  color: AppColors.calmTeal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.calmTeal.withValues(
                    alpha: 0.7 + _pulseController.value * 0.3,
                  ),
                  size: isDesktop ? 24 : 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name.isNotEmpty
                          ? "I'm watching your progress, ${profile.name}"
                          : "I'm watching your progress",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bestMode != null
                          ? 'You learn best with ${bestMode.key.toString().split('.').last.replaceAll('_', ' ')} right now'
                          : "I'm still learning how you learn best",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 20, color: AppColors.calmTeal),
            const SizedBox(width: 8),
            Text(
              'Ask the AI Tutor',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              ..._messages.map((message) => _buildMessageBubble(context, message)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Explain linear equations...',
                        prefixIcon: Icon(Icons.auto_awesome_outlined),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'Send message to AI tutor',
                    child: FilledButton(
                      onPressed: _sendMessage,
                      child: const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, TutorMessage message) {
    final isTutor = message.isTutor;
    final color = isTutor ? AppColors.calmTeal : AppColors.sereneBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isTutor ? Icons.auto_awesome : Icons.person_outline,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTutor ? 'AI Tutor' : 'You',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedForYou(BuildContext context,
      List<LearningRecommendation> recs, LearnerProfile profile) {
    final displayRecs =
        recs.length > 3 ? recs.sublist(0, 3) : recs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 20, color: AppColors.calmTeal),
            const SizedBox(width: 8),
            Text(
              'AI Recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your ${profile.modeWeights.values.fold(0.0, (a, b) => a + b) > 0 ? 'learning patterns and progress' : 'initial preferences'}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        if (displayRecs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: AppColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Complete a few sessions and I will personalize recommendations for you.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          ...displayRecs.asMap().entries.map((entry) {
            final i = entry.key;
            final rec = entry.value;
            return _buildRecommendationCard(
                context, rec, i, profile, recs);
          }),
      ],
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    LearningRecommendation rec,
    int index,
    LearnerProfile profile,
    List<LearningRecommendation> recs,
  ) {
    final colors = [AppColors.calmTeal, AppColors.softPurple, AppColors.warmCoral];
    final color = colors[index % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: 'AI recommends: ${rec.title}',
        child: GestureDetector(
          onTap: () => _launchRecommendation(context, rec, profile),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        rec.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      if (rec.reason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          rec.reason,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppColors.calmTeal,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(rec.confidence * 100).round()}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rec.estimatedDuration ~/ 60} min',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLearningStyleInsights(
      BuildContext context, LearnerProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insights, size: 20, color: AppColors.softPurple),
            const SizedBox(width: 8),
            Text(
              'What I\'ve Learned About You',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildInsightRow(
                context,
                Icons.speed_outlined,
                'Pacing',
                profile.pacing.toString().split('.').last,
                _pacingExplanation(profile.pacing),
              ),
              const Divider(height: 24),
              _buildInsightRow(
                context,
                Icons.tune_outlined,
                'Depth',
                '${(profile.depthPreference * 100).round()}%',
                _depthExplanation(profile.depthPreference),
              ),
              const Divider(height: 24),
              _buildInsightRow(
                context,
                Icons.feedback_outlined,
                'Feedback Style',
                profile.preferredFeedback.toString().split('.').last,
                _feedbackExplanation(profile.preferredFeedback),
              ),
              const Divider(height: 24),
              _buildInsightRow(
                context,
                Icons.timer_outlined,
                'Focus Threshold',
                '${(profile.focusThreshold * 100).round()}%',
                _focusExplanation(profile.focusThreshold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow(BuildContext context, IconData icon, String label,
      String value, String explanation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const Spacer(),
            Text(
              value[0].toUpperCase() + value.substring(1),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.calmTeal,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          explanation,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, AppState appState,
      List<LearningRecommendation> recs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                Icons.quiz_outlined,
                'Quick Quiz',
                AppColors.warmCoral,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                Icons.bolt_outlined,
                'Micro Lesson',
                AppColors.calmTeal,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LearningSessionScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                Icons.style_outlined,
                'Flashcards',
                AppColors.softPurple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FlashcardScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                Icons.timer_outlined,
                'Focus Sprint',
                AppColors.success,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FocusModeScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionHistoryInsight(
      BuildContext context, SessionState sessionState) {
    final sessions = sessionState.sessions;
    final count = sessions.length;

    if (count == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.trending_up,
                color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start your learning journey',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Complete a session and I will track your progress here.',
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
    }

    final avgEngagement = sessionState.averageEngagement;
    final avgComp = sessionState.averageComprehension;
    final completed = sessions.where((s) => s.completed).length;
    final recentTrend = sessions.length >= 3
        ? sessions
            .reversed
            .take(3)
            .map((s) => s.engagementScore)
            .toList()
        : <double>[];

    String trend;
    if (recentTrend.length >= 3) {
      if (recentTrend[0] > recentTrend[1] &&
          recentTrend[1] > recentTrend[2]) {
        trend = 'Improving';
      } else if (recentTrend[0] < recentTrend[1] &&
          recentTrend[1] < recentTrend[2]) {
        trend = 'Declining';
      } else {
        trend = 'Steady';
      }
    } else {
      trend = 'Getting started';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_outlined,
                size: 20, color: AppColors.calmTeal),
            const SizedBox(width: 8),
            Text(
              'Your Progress Snapshot',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCircle(context, '$count', 'Sessions',
                      AppColors.calmTeal),
                  _buildStatCircle(
                      context,
                      '${(avgEngagement * 100).round()}%',
                      'Engagement',
                      AppColors.warmCoral),
                  _buildStatCircle(
                      context,
                      '${(avgComp * 100).round()}%',
                      'Comprehension',
                      AppColors.softPurple),
                  _buildStatCircle(
                      context, '$completed', 'Done', AppColors.success),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _trendColor(trend).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _trendIcon(trend),
                      size: 16,
                      color: _trendColor(trend),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Trend: $trend',
                      style: TextStyle(
                        color: _trendColor(trend),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCircle(
      BuildContext context, String value, String label, Color color) {
    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.breakpointDesktop;
    final circleSize = isDesktop ? 44.0 : 52.0;
    final fontSize = isDesktop ? 14.0 : 16.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _trendColor(String trend) {
    switch (trend) {
      case 'Improving':
        return AppColors.success;
      case 'Declining':
        return AppColors.warmCoral;
      default:
        return AppColors.calmTeal;
    }
  }

  IconData _trendIcon(String trend) {
    switch (trend) {
      case 'Improving':
        return Icons.trending_up;
      case 'Declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  String _pacingExplanation(PacingPreference pacing) {
    switch (pacing) {
      case PacingPreference.slow:
        return 'You prefer thorough, unhurried sessions. I will keep explanations detailed and give you plenty of time.';
      case PacingPreference.moderate:
        return 'Balanced pacing works well for you. I will maintain a steady, comfortable rhythm.';
      case PacingPreference.fast:
        return 'You like to move quickly. I will keep things concise and let you dive deeper when you choose.';
    }
  }

  String _depthExplanation(double depth) {
    if (depth < 0.3) {
      return 'You prefer surface-level overviews. I will keep things simple and focused on key points.';
    } else if (depth < 0.6) {
      return 'You like a balanced mix of overview and detail. I will provide enough depth to keep you engaged.';
    } else {
      return 'You enjoy deep dives. I will provide rich detail and advanced concepts when you are ready.';
    }
  }

  String _feedbackExplanation(FeedbackStyle style) {
    switch (style) {
      case FeedbackStyle.encouraging:
        return 'You respond best to warm, supportive feedback. I will celebrate your progress and encourage effort.';
      case FeedbackStyle.direct:
        return 'You prefer clear, straightforward feedback. I will be direct and focus on what to improve.';
      case FeedbackStyle.playful:
        return 'You enjoy a lighthearted approach. I will keep things fun and engaging.';
      case FeedbackStyle.calm:
        return 'You prefer calm, quiet feedback. I will keep things gentle and low-pressure.';
      case FeedbackStyle.detailed:
        return 'You like thorough explanations. I will give you detailed breakdowns of your performance.';
    }
  }

  String _focusExplanation(double threshold) {
    if (threshold < 0.4) {
      return 'Your focus needs vary. I will suggest shorter sessions with frequent breaks.';
    } else if (threshold < 0.7) {
      return 'Your focus is building. I will suggest moderate session lengths with optional breaks.';
    } else {
      return 'You have strong focus endurance. I will suggest longer, deeper work sessions.';
    }
  }

  void _launchRecommendation(BuildContext context,
      LearningRecommendation rec, LearnerProfile profile) {
    if (rec.contentId != null) {
      setState(() => _activeContentId = StudyNavigation.contentForRecommendation(rec)?.id ?? rec.contentId);
    }
    StudyNavigation.launchRecommendation(context, rec);
  }
}
