import '../core/constants.dart';
import '../models/tutor_message.dart';
import 'shared_preferences_adapter.dart';

class TutorStorage {
  static const _maxMessages = 50;

  Future<TutorConversation> loadConversation() async {
    final json = SharedPrefsAdapter.getString(AppConstants.prefTutorConversation);
    if (json == null) {
      return const TutorConversation();
    }
    return TutorConversation.fromJsonString(json);
  }

  Future<void> saveConversation(TutorConversation conversation) async {
    final trimmed = conversation.messages.length > _maxMessages
        ? conversation.messages.sublist(conversation.messages.length - _maxMessages)
        : conversation.messages;
    final payload = TutorConversation(
      messages: trimmed,
      lastContentId: conversation.lastContentId,
    );
    await SharedPrefsAdapter.setString(
      AppConstants.prefTutorConversation,
      payload.toJsonString(),
    );
  }
}
