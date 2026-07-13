import 'dart:async';
import 'dart:html' as html;

class SpeechService {
  html.SpeechRecognition? _recognition;
  bool _isRecording = false;
  StreamSubscription? _resultSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _endSub;

  bool get isAvailable => _recognition != null;

  Future<void> initialize() async {
    if (_recognition != null) return;
    try {
      _recognition = html.SpeechRecognition();
    } catch (_) {}
  }

  void startListening({
    required void Function(String text) onPartialResult,
    required void Function(String text) onResult,
    void Function(String error)? onError,
  }) {
    if (_recognition == null) return;

    _cancelSubscriptions();

    _isRecording = true;
    _recognition!
      ..continuous = true
      ..interimResults = true
      ..lang = 'en-US'
      ..maxAlternatives = 1;

    _resultSub = _recognition!.onResult.listen((event) {
      if (!_isRecording) return;
      final results = event.results;
      if (results == null) return;
      for (var i = 0; i < results.length; i++) {
        final result = results[i] as html.SpeechRecognitionResult;
        final alternative = result.item(0);
        if (alternative == null) continue;
        final transcript = alternative.transcript ?? '';
        if (result.isFinal == true) {
          onResult(transcript);
        } else {
          onPartialResult(transcript);
        }
      }
    });

    _errorSub = _recognition!.onError.listen((event) {
      final message = (event as dynamic).error?.toString() ?? 'unknown';
      if (onError != null) {
        onError(message);
      }
    });

    _endSub = _recognition!.onEnd.listen((_) {
      // Chrome ends sessions unexpectedly; auto-restart if still recording
      if (_isRecording) {
        _recognition!.start();
      }
    });

    _recognition!.start();
  }

  void stopListening() {
    _isRecording = false;
    _recognition?.stop();
    _cancelSubscriptions();
  }

  void cancel() {
    _isRecording = false;
    _recognition?.abort();
    _cancelSubscriptions();
  }

  void _cancelSubscriptions() {
    _resultSub?.cancel();
    _resultSub = null;
    _errorSub?.cancel();
    _errorSub = null;
    _endSub?.cancel();
    _endSub = null;
  }
}
