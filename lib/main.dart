import 'package:flutter/material.dart';
import 'app.dart';
import 'persistence/shared_preferences_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefsAdapter.init();
  runApp(const ClarityCrewApp());
}
