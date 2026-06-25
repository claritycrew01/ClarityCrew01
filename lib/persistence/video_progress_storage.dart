import 'dart:convert';

import '../core/constants.dart';
import 'shared_preferences_adapter.dart';

class VideoProgressStorage {
  Future<Map<String, dynamic>> loadAll() async {
    final json = SharedPrefsAdapter.getString(AppConstants.prefVideoProgress);
    if (json == null) return {};
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> loadForVideo(String videoId) async {
    final all = await loadAll();
    final entry = all[videoId];
    if (entry is Map<String, dynamic>) return entry;
    return null;
  }

  Future<void> saveForVideo(
    String videoId, {
    required bool watched,
    int positionMs = 0,
  }) async {
    final all = await loadAll();
    all[videoId] = {
      'watched': watched,
      'positionMs': positionMs,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await SharedPrefsAdapter.setString(
      AppConstants.prefVideoProgress,
      jsonEncode(all),
    );
  }
}
