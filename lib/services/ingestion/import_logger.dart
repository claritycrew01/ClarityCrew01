import 'dart:io';

class ImportLogger {
  final String id;
  final List<String> _buffer = [];
  bool _quiet;

  ImportLogger({required this.id, bool quiet = false}) : _quiet = quiet;

  List<String> get entries => List.unmodifiable(_buffer);

  void info(String message) => _log('INFO', message);
  void warn(String message) => _log('WARN', message);
  void error(String message) => _log('ERROR', message);

  void _log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final line = '[$timestamp] [$level] $message';
    _buffer.add(line);
    if (!_quiet) {
      if (level == 'ERROR') {
        stderr.writeln(line);
      } else {
        stdout.writeln(line);
      }
    }
  }

  ImportLogger subLogger(String subId) {
    final child = ImportLogger(id: '$id/$subId', quiet: _quiet);
    return child;
  }
}
