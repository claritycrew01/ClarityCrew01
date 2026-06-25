import '../models/learner_profile.dart';
import '../models/session_record.dart';
import 'session_analyzer.dart';

class ProgressTracker {
  final SessionAnalyzer _analyzer = SessionAnalyzer();

  LearnerProfile updateProgress(
    LearnerProfile profile,
    SessionRecord session,
  ) {
    final summary = _analyzer.analyze(session);
    final updatedEngagement = _updateEngagementScores(profile, summary);
    final updatedThreshold = _updateFocusThreshold(profile, summary);

    return profile.copyWith(
      engagementHistory: updatedEngagement,
      focusThreshold: updatedThreshold,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, double> _updateEngagementScores(
    LearnerProfile profile,
    SessionSummary summary,
  ) {
    final history = Map<String, double>.from(profile.engagementHistory);
    final key = summary.dominantContentType;
    history[key] =
        (history[key] ?? 0.5) * 0.7 + summary.engagementScore * 0.3;
    return history;
  }

  double _updateFocusThreshold(
    LearnerProfile profile,
    SessionSummary summary,
  ) {
    double threshold = profile.focusThreshold;
    if (summary.skippedCount > summary.totalInteractions * 0.3) {
      threshold -= 0.05;
    }
    if (summary.completionRate > 0.8) {
      threshold += 0.03;
    }
    if (summary.struggledCount > summary.totalInteractions * 0.4) {
      threshold -= 0.05;
    }
    return threshold.clamp(0.2, 1.0);
  }

  double computeOverallProgress(List<SessionRecord> sessions) {
    if (sessions.isEmpty) return 0.0;
    final scores = sessions.map((s) => s.comprehensionScore).toList();
    final recent = scores.length > 5
        ? scores.sublist(scores.length - 5)
        : scores;
    return recent.reduce((a, b) => a + b) / recent.length;
  }

  double computeStreak(List<SessionRecord> sessions) {
    if (sessions.isEmpty) return 0.0;
    double streak = 0.0;
    for (final session in sessions.reversed) {
      if (session.completed && session.engagementScore > 0.5) {
        streak += 1.0;
      } else {
        break;
      }
    }
    return streak;
  }
}
