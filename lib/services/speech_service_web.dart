import 'dart:async';
import 'dart:html' as html;

class SpeechService {
  html.SpeechRecognition? _recognition;
  bool _isListening = false;

  bool get isAvailable => _recognition != null;

  Future<void> initialize() async {
    if (_recognition != null) return;
    try {
      _recognition = html.SpeechRecognition();
    } catch (_) {
      try {
        _recognition =
            (html.window as dynamic).webkitSpeechRecognition?.new();
      } catch (_) {}
    }
  }

  void startListening({
    required void Function(String text) onPartialResult,
    required void Function(String text) onResult,
  }) {
    if (_recognition == null) return;
    _isListening = true;
    _recognition!
      ..continuous = true
      ..interimResults = true
      ..lang = 'en-US'
      ..maxAlternatives = 1
      ..onResult = (event) {
        for (var i = event.results.length - 1; i >= 0; i--) {
          final result = event.results[i] as html.SpeechRecognitionResult;
          final transcript = result.first.transcript;
          if (result.isFinal) {
            onResult(transcript);
          } else {
            onPartialResult(transcript);
          }
        }
      }
      ..onError = (_) {
        _isListening = false;
      }
      ..onEnd = (_) {
        _isListening = false;
      }
      ..start();
  }

  void stopListening() {
    _recognition?.stop();
    _isListening = false;
  }

  void cancel() {
    _recognition?.abort();
    _isListening = false;
  }
}
