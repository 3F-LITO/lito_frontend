import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/local/database_helper.dart';
import 'core/local/preferences.dart';
import 'providers/farm_provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/connectivity_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite tidak support Flutter Web — skip di platform web
  if (!kIsWeb) {
    await DatabaseHelper.instance.database;
  }

  // Inisialisasi locale Indonesia untuk DateFormat & NumberFormat
  await initializeDateFormatting('id', null);

  // Inisialisasi SharedPreferences lokal
  await Preferences.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FarmProvider()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const LitoApp(),
    ),
  );
}
