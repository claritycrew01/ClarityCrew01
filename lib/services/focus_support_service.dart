import 'dart:async';
import '../models/learner_profile.dart';

class FocusSupportService {
  Timer? _focusTimer;
  Timer? _breakTimer;
  int _elapsedSeconds = 0;
  int _focusDuration = 1500;
  bool _isRunning = false;
  bool _isBreak = false;

  final _focusStateController = StreamController<FocusState>.broadcast();
  Stream<FocusState> get focusStateStream => _focusStateController.stream;

  FocusState get currentState => FocusState(
        elapsedSeconds: _elapsedSeconds,
        totalSeconds: _focusDuration,
        isRunning: _isRunning,
        isBreak: _isBreak,
      );

  void startFocus({int? durationSeconds}) {
    _focusDuration = durationSeconds ?? _focusDuration;
    _elapsedSeconds = 0;
    _isRunning = true;
    _isBreak = false;
    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _focusStateController.add(currentState);
      if (_elapsedSeconds >= _focusDuration) {
        _completeFocus();
      }
    });
    _focusStateController.add(currentState);
  }

  void startBreak({int durationSeconds = 300}) {
    _focusTimer?.cancel();
    _focusDuration = durationSeconds;
    _elapsedSeconds = 0;
    _isRunning = true;
    _isBreak = true;
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _focusStateController.add(currentState);
      if (_elapsedSeconds >= _focusDuration) {
        _completeBreak();
      }
    });
    _focusStateController.add(currentState);
  }

  void pause() {
    _isRunning = false;
    _focusStateController.add(currentState);
  }

  void resume() {
    _isRunning = true;
    _focusStateController.add(currentState);
  }

  void stop() {
    _focusTimer?.cancel();
    _breakTimer?.cancel();
    _isRunning = false;
    _elapsedSeconds = 0;
    _focusStateController.add(currentState);
  }

  void adjustDuration(int seconds) {
    _focusDuration = seconds.clamp(60, 7200);
    _focusStateController.add(currentState);
  }

  bool get requiresBreak {
    if (!_isRunning || _isBreak) return false;
    return _elapsedSeconds >= _focusDuration * 0.8;
  }

  int get recommendedBreakDuration {
    if (_elapsedSeconds > 3600) return 600;
    if (_elapsedSeconds > 1800) return 420;
    return 300;
  }

  int getTimeRemaining() => _focusDuration - _elapsedSeconds;

  double getProgress() =>
      (_elapsedSeconds / _focusDuration).clamp(0.0, 1.0);

  void _completeFocus() {
    _focusTimer?.cancel();
    _isRunning = false;
    _focusStateController.add(currentState);
  }

  void _completeBreak() {
    _breakTimer?.cancel();
    _isRunning = false;
    _isBreak = false;
    _focusStateController.add(currentState);
  }

  void dispose() {
    _focusTimer?.cancel();
    _breakTimer?.cancel();
    _focusStateController.close();
  }
}

class FocusState {
  final int elapsedSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isBreak;

  const FocusState({
    required this.elapsedSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.isBreak,
  });

  int get remainingSeconds => totalSeconds - elapsedSeconds;
  double get progress => (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  String get formattedTime {
    final remaining = remainingSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
