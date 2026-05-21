import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lito_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabel Farms (Fase 1)
    await db.execute('''
      CREATE TABLE farms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        size_m2 REAL NOT NULL,
        shrimp_type TEXT NOT NULL,
        stocking_date TEXT NOT NULL,
        stocking_count INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Tabel Sensor Readings (Fase 2)
    await db.execute('''
      CREATE TABLE sensor_readings (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        do_level REAL NOT NULL,
        temperature REAL NOT NULL,
        salinity REAL NOT NULL,
        ph REAL NOT NULL,
        is_simulated INTEGER NOT NULL
      )
    ''');

    // 3. Tabel Recommendations (Fase 4)
    await db.execute('''
      CREATE TABLE recommendations (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        do_level REAL NOT NULL,
        temperature REAL NOT NULL,
        salinity REAL NOT NULL,
        ph REAL NOT NULL,
        water_color INTEGER NOT NULL,
        shrimp_condition INTEGER NOT NULL,
        appetite INTEGER NOT NULL,
        weather INTEGER NOT NULL,
        pond_bottom INTEGER NOT NULL,
        doc INTEGER NOT NULL,
        main_action TEXT NOT NULL,
        actions TEXT NOT NULL, -- Di-serialize ke JSON string
        priority TEXT NOT NULL,
        shap_top3 TEXT NOT NULL, -- Di-serialize ke JSON string
        explanation TEXT NOT NULL,
        feed_dose_kg REAL NOT NULL,
        confidence REAL NOT NULL
      )
    ''');

    // 4. Tabel Alerts (Fase 3)
    await db.execute('''
      CREATE TABLE alerts (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        parameter TEXT NOT NULL,
        value REAL NOT NULL,
        threshold REAL NOT NULL,
        urgency TEXT NOT NULL,
        action_text TEXT NOT NULL,
        is_read INTEGER NOT NULL
      )
    ''');

    // 5. Tabel Daily Logs (Fase 2.6)
    await _createDailyLogsTable(db);
  }

  Future<void> _createDailyLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_logs (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        date TEXT NOT NULL,
        actions TEXT NOT NULL,
        notes TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDailyLogsTable(db);
    }
    if (oldVersion < 3) {
      // Tambah kolom is_synced ke farms
      await db.execute(
        'ALTER TABLE farms ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
