// Common interface — exports the right implementation per platform.
// Web uses dart:html's SpeechRecognition directly.
// Mobile/desktop uses the speech_to_text package.
export 'speech_service_web.dart'
    if (dart.library.io) 'speech_service_io.dart';
