import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io' show Platform;
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

  // Inisialisasi sqflite FFI khusus Windows/Linux (macOS & mobile sudah native)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inisialisasi cache SQLite lokal
  await DatabaseHelper.instance.database; 

  // Inisialisasi SharedPreferences lokal
  await Preferences.init();

  // Inisialisasi locale data untuk intl (DateFormat, dll)
  await initializeDateFormatting('id', null);

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