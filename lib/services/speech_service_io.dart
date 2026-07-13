import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  stt.SpeechToText? _speech;
  bool _isInitialized = false;

  bool get isAvailable => _speech != null && _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _speech = stt.SpeechToText();
      _isInitialized = await _speech!.initialize();
    } catch (_) {
      _isInitialized = false;
    }
  }

  Future<void> startListening({
    required void Function(String text) onPartialResult,
    required void Function(String text) onResult,
  }) async {
    if (_speech == null) return;
    try {
      await _speech!.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          if (result.finalResult) {
            onResult(text);
          } else {
            onPartialResult(text);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    } catch (_) {}
  }

  void stopListening() {
    _speech?.stop();
  }

  void cancel() {
    _speech?.cancel();
  }
}
