import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'state/learner_state.dart';
import 'state/session_state.dart';
import 'state/app_state.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';

class ClarityCrewApp extends StatelessWidget {
  const ClarityCrewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LearnerState()),
        ChangeNotifierProvider(create: (_) => SessionState()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: Consumer2<LearnerState, AppState>(
        builder: (context, learnerState, appState, _) {
          return MaterialApp(
            title: 'ClarityCrew',
            debugShowCheckedModeBanner: false,
            theme: appState.isDarkMode ? AppTheme.dark : AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: _buildHome(context, learnerState),
          );
        },
      ),
    );
  }

  Widget _buildHome(BuildContext context, LearnerState learnerState) {
    if (learnerState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (learnerState.isNewUser) {
      return const OnboardingScreen();
    }

    return const HomeScreen();
  }
}
