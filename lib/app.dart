import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'state/learner_state.dart';
import 'state/session_state.dart';
import 'state/app_state.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'services/content/content_repository.dart';
import 'widgets/responsive_wrapper.dart';

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
          final profile = learnerState.profile;
          final baseTheme = appState.isDarkMode ? AppTheme.dark : AppTheme.light;

          final theme = profile.prefersHighContrast
              ? baseTheme.copyWith(
                  colorScheme: baseTheme.colorScheme.copyWith(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    secondary: Colors.black,
                    onSecondary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                    error: Colors.red.shade900,
                    onError: Colors.white,
                  ),
                  scaffoldBackgroundColor: Colors.white,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                )
              : baseTheme;

          final darkTheme = profile.prefersHighContrast
              ? AppTheme.dark.copyWith(
                  colorScheme: AppTheme.dark.colorScheme.copyWith(
                    primary: Colors.white,
                    onPrimary: Colors.black,
                    secondary: Colors.white,
                    onSecondary: Colors.black,
                    surface: Colors.black,
                    onSurface: Colors.white,
                    error: Colors.red.shade200,
                    onError: Colors.black,
                  ),
                  scaffoldBackgroundColor: Colors.black,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                )
              : AppTheme.dark;

          return MaterialApp(
            title: 'ClarityCrew',
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: darkTheme,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: _buildHome(context, learnerState),
            builder: (context, child) {
              child = ResponsiveWrapper(child: child!);
              if (profile.fontSizeMultiplier != 1.0) {
                child = MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(profile.fontSizeMultiplier),
                  ),
                  child: child,
                );
              }
              return child;
            },
          );
        },
      ),
    );
  }

  Widget _buildHome(BuildContext context, LearnerState learnerState) {
    if (learnerState.isLoading || !ContentRepository.isInitialized) {
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
