import 'package:flutter/material.dart';
import 'app.dart';
import 'persistence/shared_preferences_adapter.dart';
import 'services/content/content_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefsAdapter.init();
  await ContentRepository.initialize();
  runApp(const ClarityCrewApp());
}
