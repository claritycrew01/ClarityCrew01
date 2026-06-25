import '../models/session_record.dart';
import '../models/interaction_event.dart';
import '../models/learner_profile.dart';

class SessionAnalyzer {
  SessionSummary analyze(SessionRecord session) {
    final interactions = session.interactions;
    if (interactions.isEmpty) {
      return SessionSummary.empty();
    }

    final completedCount = interactions
        .where((i) => i.interactionType == 'completed')
        .length;
    final struggledCount = interactions
        .where((i) => i.interactionType == 'struggled')
        .length;
    final skippedCount = interactions
        .where((i) => i.interactionType == 'skipped')
        .length;
    final hintCount = interactions
        .where((i) => i.interactionType == 'tappedHint')
        .length;

    final totalScore = interactions
        .where((i) => i.score != null)
        .fold<int>(0, (sum, i) => sum + (i.score ?? 0));
    final scoredCount = interactions
        .where((i) => i.score != null)
        .length;

    final engagementScore = _computeEngagement(interactions);
    final comprehensionScore = scoredCount > 0
        ? (totalScore / (scoredCount * 100)).clamp(0.0, 1.0)
        : engagementScore * 0.7;

    final dominantContent = _findDominantContentType(interactions);
    final averageDuration = interactions.isEmpty
        ? 0.0
        : interactions.fold<double>(
              0.0, (sum, i) => sum + i.durationSeconds) /
          interactions.length;

    return SessionSummary(
      totalInteractions: interactions.length,
      completedCount: completedCount,
      struggledCount: struggledCount,
      skippedCount: skippedCount,
      hintCount: hintCount,
      engagementScore: engagementScore,
      comprehensionScore: comprehensionScore,
      averageResponseDuration: averageDuration,
      dominantContentType: dominantContent,
      completionRate: interactions.isEmpty
          ? 0.0
          : completedCount / interactions.length,
    );
  }

  double _computeEngagement(List<InteractionEvent> interactions) {
    if (interactions.isEmpty) return 0.0;
    double score = 0.0;
    for (final event in interactions) {
      if (event.wasSuccessful) score += 0.3;
      if (event.durationSeconds > 30) score += 0.2;
      if (event.interactionType == 'replayed') score += 0.2;
      if (event.interactionType == 'lingered') score += 0.15;
      if (event.interactionType == 'completed') score += 0.25;
      if (event.interactionType == 'skipped') score -= 0.2;
      if (event.interactionType == 'timedOut') score -= 0.15;
    }
    return (score / interactions.length).clamp(0.0, 1.0);
  }

  String _findDominantContentType(List<InteractionEvent> interactions) {
    final counts = <String, int>{};
    for (final event in interactions) {
      counts[event.contentType] = (counts[event.contentType] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'unknown';
    return counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<String> getWeakAreas(SessionRecord session) {
    final weak = <String>[];
    final byType = <String, List<InteractionEvent>>{};
    for (final event in session.interactions) {
      byType.putIfAbsent(event.contentType, () => []).add(event);
    }
    for (final entry in byType.entries) {
      final failed = entry.value.where((e) => !e.wasSuccessful).length;
      if (entry.value.isNotEmpty &&
          failed / entry.value.length > 0.4) {
        weak.add(entry.key);
      }
    }
    return weak;
  }

  Map<DateTime, double> getEngagementTimeline(SessionRecord session) {
    final timeline = <DateTime, double>{};
    for (final event in session.interactions) {
      timeline[event.timestamp] = event.wasSuccessful ? 1.0 : 0.0;
    }
    return timeline;
  }
}

class SessionSummary {
  final int totalInteractions;
  final int completedCount;
  final int struggledCount;
  final int skippedCount;
  final int hintCount;
  final double engagementScore;
  final double comprehensionScore;
  final double averageResponseDuration;
  final String dominantContentType;
  final double completionRate;

  const SessionSummary({
    required this.totalInteractions,
    required this.completedCount,
    required this.struggledCount,
    required this.skippedCount,
    required this.hintCount,
    required this.engagementScore,
    required this.comprehensionScore,
    required this.averageResponseDuration,
    required this.dominantContentType,
    required this.completionRate,
  });

  factory SessionSummary.empty() => const SessionSummary(
        totalInteractions: 0,
        completedCount: 0,
        struggledCount: 0,
        skippedCount: 0,
        hintCount: 0,
        engagementScore: 0.0,
        comprehensionScore: 0.0,
        averageResponseDuration: 0.0,
        dominantContentType: 'none',
        completionRate: 0.0,
      );
}
