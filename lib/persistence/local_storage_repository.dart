import 'dart:convert';
import '../models/learner_profile.dart';
import '../models/session_record.dart';
import '../models/content_item.dart';
import '../models/learning_recommendation.dart';
import 'shared_preferences_adapter.dart';
import 'serialization.dart';
import '../core/constants.dart';

class LocalStorageRepository {
  Future<void> saveLearnerProfile(LearnerProfile profile) async {
    final json = Serialization.learnerProfileToJson(profile);
    await SharedPrefsAdapter.setString(
      AppConstants.prefLearnerProfile,
      json,
    );
  }

  Future<LearnerProfile?> loadLearnerProfile() async {
    final json = SharedPrefsAdapter.getString(AppConstants.prefLearnerProfile);
    if (json == null) return null;
    return Serialization.learnerProfileFromJson(json);
  }

  Future<void> saveSessionHistory(List<SessionRecord> records) async {
    final json = Serialization.sessionListToJson(records);
    await SharedPrefsAdapter.setString(
      AppConstants.prefSessionHistory,
      json,
    );
  }

  Future<List<SessionRecord>> loadSessionHistory() async {
    final json = SharedPrefsAdapter.getString(AppConstants.prefSessionHistory);
    if (json == null) return [];
    return Serialization.sessionListFromJson(json);
  }

  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    final json = _toJsonString(settings);
    await SharedPrefsAdapter.setString(AppConstants.prefAppSettings, json);
  }

  Future<Map<String, dynamic>> loadAppSettings() async {
    final json = SharedPrefsAdapter.getString(AppConstants.prefAppSettings);
    if (json == null) return {};
    return _fromJsonString(json);
  }

  Future<void> saveAccessibilitySettings(Map<String, dynamic> settings) async {
    final json = _toJsonString(settings);
    await SharedPrefsAdapter.setString(
      AppConstants.prefAccessibility,
      json,
    );
  }

  Future<Map<String, dynamic>> loadAccessibilitySettings() async {
    final json =
        SharedPrefsAdapter.getString(AppConstants.prefAccessibility);
    if (json == null) return {};
    return _fromJsonString(json);
  }

  Future<void> clearAll() async {
    await SharedPrefsAdapter.clear();
  }
}

String _toJsonString(Map<String, dynamic> map) =>
    const JsonEncoder().convert(map);

Map<String, dynamic> _fromJsonString(String json) =>
    const JsonDecoder().convert(json) as Map<String, dynamic>;
