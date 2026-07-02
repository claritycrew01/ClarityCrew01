import '../../models/tutor_message.dart';

class ConversationHistory {
  final List<TutorMessage> _messages;

  const ConversationHistory(this._messages);

  bool get isEmpty => _messages.isEmpty;
  int get length => _messages.length;
  List<TutorMessage> get messages => List.unmodifiable(_messages);

  String? get lastTutorResponse {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isTutor) return _messages[i].text;
    }
    return null;
  }

  String? get lastUserQuery {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) return _messages[i].text;
    }
    return null;
  }

  bool get hasPreviousExchange => _messages.length >= 2;

  bool isLikelyReferencingPreviousTopic(String userMessage) {
    final short = userMessage.trim().length < 20;
    final followUp = RegExp(
      r'\b(tell me more|explain that|go on|what about|and then|'
      r'how about|also|more detail|still|clarify|'
      r'like what|for example|like|such as|that part|that bit)\b',
      caseSensitive: false,
    ).hasMatch(userMessage);
    return short || followUp;
  }

  String? extractLastTopic() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isTutor) {
        final match = RegExp(r'"([^"]+)"').firstMatch(_messages[i].text);
        if (match != null) return match.group(1);
      }
    }
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        for (final lesson in _knownLessons) {
          if (_messages[i].text.toLowerCase().contains(lesson.toLowerCase())) {
            return lesson;
          }
        }
      }
    }
    return null;
  }

  String? get mostRecentContentId {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].contentId != null) return _messages[i].contentId;
    }
    return null;
  }

  int exchangeCount(String role) {
    return _messages.where((m) => m.role == role).length;
  }

  int get totalExchanges => exchangeCount('user');

  List<String> gatherQueryTerms() {
    final terms = <String>{};
    for (final msg in _messages) {
      if (msg.isUser) {
        for (final word in msg.text.split(RegExp(r'\s+'))) {
          if (word.length > 3) terms.add(word.toLowerCase());
        }
      }
    }
    return terms.toList();
  }

  String buildConversationSummary() {
    if (_messages.length < 2) return '';
    final recent = _messages.length > 6
        ? _messages.sublist(_messages.length - 6)
        : _messages;
    return recent
        .map((m) => '${m.isUser ? "User" : "Tutor"}: ${m.text.split('\n').first}')
        .join('\n');
  }

  static const _knownLessons = [
    'algebra',
    'biology',
    'chemistry',
    'physics',
    'english',
    'history',
    'geography',
    'computer science',
    'mathematics',
    'geometry',
    'trigonometry',
    'calculus',
    'statistics',
    'economics',
    'psychology',
    'philosophy',
    'literature',
    'writing',
    'grammar',
    'vocabulary',
    'reading',
    'science',
    'art',
    'music',
  ];
}
