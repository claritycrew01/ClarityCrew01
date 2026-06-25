import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/session_record.dart';
import '../models/interaction_event.dart';
import '../models/content_item.dart';
import '../persistence/local_storage_repository.dart';

class SessionState extends ChangeNotifier {
  final LocalStorageRepository _repo = LocalStorageRepository();
  final Uuid _uuid = const Uuid();

  List<SessionRecord> _sessions = [];
  SessionRecord? _currentSession;
  bool _isLoading = true;
  int _activeContentIndex = 0;
  List<ContentItem> _activeContent = [];
  bool _isInSession = false;

  List<SessionRecord> get sessions => _sessions;
  SessionRecord? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  bool get isInSession => _isInSession;
  List<ContentItem> get activeContent => _activeContent;
  int get activeContentIndex => _activeContentIndex;
  ContentItem? get currentContent =>
      _activeContent.isNotEmpty && _activeContentIndex < _activeContent.length
          ? _activeContent[_activeContentIndex]
          : null;

  SessionState() {
    _initialize();
  }

  Future<void> _initialize() async {
    _sessions = await _repo.loadSessionHistory();
    _isLoading = false;
    notifyListeners();
  }

  void startSession(String learnerId, {String type = 'general'}) {
    _currentSession = SessionRecord(
      id: _uuid.v4(),
      learnerId: learnerId,
      startTime: DateTime.now(),
      sessionType: type,
    );
    _isInSession = true;
    _activeContentIndex = 0;
    notifyListeners();
  }

  void setActiveContent(List<ContentItem> content, {String? startContentId}) {
    _activeContent = content;
    _activeContentIndex = 0;
    if (startContentId != null) {
      final index = content.indexWhere((item) => item.id == startContentId);
      if (index >= 0) {
        _activeContentIndex = index;
      }
    }
    notifyListeners();
  }

  void advanceContent() {
    if (_activeContentIndex < _activeContent.length - 1) {
      _activeContentIndex++;
      notifyListeners();
    }
  }

  void goBackContent() {
    if (_activeContentIndex > 0) {
      _activeContentIndex--;
      notifyListeners();
    }
  }

  void recordInteraction(InteractionEvent event) {
    if (_currentSession == null) return;
    final updatedInteractions = [
      ..._currentSession!.interactions,
      event,
    ];
    _currentSession = _currentSession!.copyWith(
      interactions: updatedInteractions,
    );
    notifyListeners();
  }

  Future<void> endSession({
    double engagementScore = 0.0,
    double comprehensionScore = 0.0,
    bool completed = false,
  }) async {
    if (_currentSession == null) return;

    final ended = _currentSession!.copyWith(
      endTime: DateTime.now(),
      durationSeconds: DateTime.now()
          .difference(_currentSession!.startTime)
          .inSeconds,
      engagementScore: engagementScore,
      comprehensionScore: comprehensionScore,
      completed: completed,
    );

    _sessions = [..._sessions, ended];
    _currentSession = null;
    _isInSession = false;
    _activeContent = [];
    _activeContentIndex = 0;

    await _repo.saveSessionHistory(_sessions);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _sessions = [];
    await _repo.saveSessionHistory(_sessions);
    notifyListeners();
  }

  List<SessionRecord> getRecentSessions({int count = 10}) {
    if (_sessions.isEmpty) return [];
    final sorted = List<SessionRecord>.from(_sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sorted.take(count).toList();
  }

  double get averageEngagement {
    if (_sessions.isEmpty) return 0.0;
    return _sessions.fold<double>(0.0, (s, r) => s + r.engagementScore) /
        _sessions.length;
  }

  double get averageComprehension {
    if (_sessions.isEmpty) return 0.0;
    return _sessions.fold<double>(0.0, (s, r) => s + r.comprehensionScore) /
        _sessions.length;
  }
}
