import 'package:flutter/material.dart';
import 'core/local/preferences.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/recommendation/form/contextual_form_screen.dart';
import 'screens/recommendation/form/parameter_form_screen.dart';
import 'screens/recommendation/result/result_screen.dart';
import 'screens/history/parameter_history_screen.dart';

class LitoApp extends StatelessWidget {
  const LitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lito App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A5276),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5276),
          primary: const Color(0xFF1A5276),
          secondary: const Color(0xFF2E86AB),
          tertiary: const Color(0xFF17A589),
        ),
      ),
      initialRoute: Preferences.isOnboarded ? '/home' : '/onboarding',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const MainScreen(),
        '/recommendation/contextual': (context) => const ContextualFormScreen(),
        '/recommendation/parameter': (context) => const ParameterFormScreen(),
        '/recommendation/result': (context) => const ResultScreen(),
        '/history/parameters': (context) => const ParameterHistoryScreen(),
      },
    );
  }
}
