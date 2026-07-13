import 'dart:async';
import 'dart:html' as html;

class SpeechService {
  html.SpeechRecognition? _recognition;
  bool _isRecording = false;
  StreamSubscription? _resultSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _endSub;
  Timer? _restartTimer;

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

      final sb = StringBuffer();
      for (var i = 0; i < results.length; i++) {
        final result = results[i] as html.SpeechRecognitionResult;
        final alternative = result.item(0);
        if (alternative == null) continue;
        final transcript = alternative.transcript ?? '';
        if (transcript.isEmpty) continue;
        if (sb.isNotEmpty) sb.write(' ');
        sb.write(transcript);
      }
      final fullText = sb.toString().trim();
      if (fullText.isEmpty) return;

      final lastResult = results[results.length - 1] as html.SpeechRecognitionResult;
      if (lastResult.isFinal == true) {
        onResult(fullText);
      } else {
        onPartialResult(fullText);
      }
    });

    _errorSub = _recognition!.onError.listen((event) {
      final errorCode = (event as dynamic).error?.toString() ?? 'unknown';
      if (onError != null) {
        onError(errorCode);
      }
      // Fatal errors: stop recording so onEnd does not restart
      if (errorCode == 'network' ||
          errorCode == 'not-allowed' ||
          errorCode == 'service-not-allowed') {
        _isRecording = false;
        _restartTimer?.cancel();
        _recognition?.stop();
        _cancelSubscriptions();
      }
    });

    _endSub = _recognition!.onEnd.listen((_) {
      if (_isRecording) {
        _restartTimer = Timer(const Duration(milliseconds: 300), () {
          if (_isRecording) {
            _recognition!.start();
          }
        });
      }
    });

    _recognition!.start();
  }

  void stopListening() {
    _isRecording = false;
    _restartTimer?.cancel();
    _recognition?.stop();
    _cancelSubscriptions();
  }

  void cancel() {
    _isRecording = false;
    _restartTimer?.cancel();
    _recognition?.abort();
    _cancelSubscriptions();
  }

  void _cancelSubscriptions() {
    _restartTimer?.cancel();
    _resultSub?.cancel();
    _resultSub = null;
    _errorSub?.cancel();
    _errorSub = null;
    _endSub?.cancel();
    _endSub = null;
  }
}
