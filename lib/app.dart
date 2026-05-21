import 'package:flutter/material.dart';
// import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_screen.dart';
// import 'screens/recommendation/form/contextual_form_screen.dart';
// import 'screens/recommendation/form/parameter_form_screen.dart';
// import 'screens/recommendation/result_screen.dart';
// import 'screens/history/parameter_history_screen.dart';

class LitoApp extends StatelessWidget {
  const LitoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lito - Smart Farming Assistant',
      theme: ThemeData(
        primaryColor: const Color(0xFF1A5276),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFF2E86AB)),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A5276),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            // primary: const Color(0xFF17Af89),
            // onPrimary: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      // home: const MainScreen(),
    );
  }
}