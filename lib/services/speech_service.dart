import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _initialized = false;

  bool get isListening => _isListening;
  bool get isAvailable => _speech != null && _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _speech = stt.SpeechToText();
      _initialized = await _speech!.initialize();
    } catch (_) {
      _initialized = false;
    }
  }

  Future<String> startListening({
    required void Function(String interim) onPartialResult,
    required void Function(String finalResult) onResult,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_speech == null) return 'Speech not available';

    _isListening = true;
    String finalText = '';

    try {
      await _speech!.listen(
        onResult: (result) {
          finalText = result.recognizedWords;
          if (result.finalResult) {
            onResult(finalText);
          } else {
            onPartialResult(result.recognizedWords);
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    } catch (e) {
      _isListening = false;
      return 'Error: $e';
    }

    _isListening = false;
    return finalText;
  }

  void stopListening() {
    _isListening = false;
    _speech?.stop();
  }

  void cancel() {
    _isListening = false;
    _speech?.cancel();
  }
}
