import 'dart:async';
import 'dart:html' as html;

class SpeechService {
  html.SpeechRecognition? _recognition;
  bool _isListening = false;
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
  }) {
    if (_recognition == null) return;

    // Cancel any previous subscriptions to avoid duplicates
    _cancelSubscriptions();

    _isListening = true;
    _recognition!
      ..continuous = true
      ..interimResults = true
      ..lang = 'en-US'
      ..maxAlternatives = 1;

    _resultSub = _recognition!.onResult.listen((event) {
      if (!_isListening) return;
      final results = event.results;
      if (results == null) return;
      for (var i = 0; i < results.length; i++) {
        final result = results[i] as html.SpeechRecognitionResult;
        final alternative = result[0] as html.SpeechRecognitionAlternative?;
        if (alternative == null) continue;
        final transcript = alternative.transcript;
        if (result.isFinal == true) {
          onResult(transcript);
        } else {
          onPartialResult(transcript);
        }
      }
    });

    _errorSub = _recognition!.onError.listen((_) {
      _isListening = false;
    });

    _endSub = _recognition!.onEnd.listen((_) {
      _isListening = false;
    });

    _recognition!.start();
  }

  void stopListening() {
    _recognition?.stop();
    _isListening = false;
    _cancelSubscriptions();
  }

  void cancel() {
    _recognition?.abort();
    _isListening = false;
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
