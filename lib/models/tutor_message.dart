import 'dart:convert';

class TutorMessage {
  final String id;
  final String role;
  final String text;
  final String? contentId;
  final DateTime timestamp;

  const TutorMessage({
    required this.id,
    required this.role,
    required this.text,
    this.contentId,
    required this.timestamp,
  });

  bool get isUser => role == 'user';
  bool get isTutor => role == 'tutor';

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'text': text,
        'contentId': contentId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TutorMessage.fromJson(Map<String, dynamic> json) {
    return TutorMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      text: json['text'] as String,
      contentId: json['contentId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class TutorConversation {
  final List<TutorMessage> messages;
  final String? lastContentId;

  const TutorConversation({
    this.messages = const [],
    this.lastContentId,
  });

  TutorConversation copyWith({
    List<TutorMessage>? messages,
    String? lastContentId,
  }) {
    return TutorConversation(
      messages: messages ?? this.messages,
      lastContentId: lastContentId ?? this.lastContentId,
    );
  }

  Map<String, dynamic> toJson() => {
        'messages': messages.map((m) => m.toJson()).toList(),
        'lastContentId': lastContentId,
      };

  factory TutorConversation.fromJson(Map<String, dynamic> json) {
    return TutorConversation(
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => TutorMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lastContentId: json['lastContentId'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory TutorConversation.fromJsonString(String source) =>
      TutorConversation.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
