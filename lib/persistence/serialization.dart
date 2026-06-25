import 'dart:convert';
import '../models/learner_profile.dart';
import '../models/session_record.dart';
import '../models/content_item.dart';
import '../models/interaction_event.dart';
import '../models/learning_recommendation.dart';

class Serialization {
  static String learnerProfileToJson(LearnerProfile profile) =>
      profile.toJsonString();

  static LearnerProfile learnerProfileFromJson(String json) =>
      LearnerProfile.fromJsonString(json);

  static String sessionRecordToJson(SessionRecord record) =>
      record.toJsonString();

  static SessionRecord sessionRecordFromJson(String json) =>
      SessionRecord.fromJsonString(json);

  static String contentItemToJson(ContentItem item) => item.toJsonString();

  static ContentItem contentItemFromJson(String json) =>
      ContentItem.fromJsonString(json);

  static String interactionEventToJson(InteractionEvent event) =>
      event.toJsonString();

  static InteractionEvent interactionEventFromJson(String json) =>
      InteractionEvent.fromJsonString(json);

  static String recommendationToJson(LearningRecommendation rec) =>
      rec.toJsonString();

  static LearningRecommendation recommendationFromJson(String json) =>
      LearningRecommendation.fromJsonString(json);

  static String sessionListToJson(List<SessionRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());

  static List<SessionRecord> sessionListFromJson(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String contentListToJson(List<ContentItem> items) =>
      jsonEncode(items.map((i) => i.toJson()).toList());

  static List<ContentItem> contentListFromJson(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
