import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import '../models/sensor_data.dart';
import '../core/network/dio_client.dart';
import '../core/local/database_helper.dart';

/// Hasil fetch sensor beserta informasi asal data (jaringan atau cache).
class SensorReadingResult {
  final SensorReading reading;
  final bool isFromCache;

  const SensorReadingResult({required this.reading, required this.isFromCache});
}

class SensorRepository {
  final Dio _dio = DioClient.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Mengambil bacaan sensor terakhir dari API.
  /// Jika jaringan tidak tersedia, mengembalikan data cache SQLite.
  Future<SensorReadingResult?> fetchLatestReading(String farmId) async {
    try {
      final response = await _dio.get(
        '/sensors/latest/',
        queryParameters: {'farm_id': farmId},
      );
      if (response.statusCode == 200 && response.data != null) {
        final reading = SensorReading.fromMap({
          ...response.data as Map<String, dynamic>,
          'farm_id': farmId,
        });

        // Cache ke SQLite (hanya di mobile)
        if (!kIsWeb) {
          final db = await _dbHelper.database;
          await db.insert(
            'sensor_readings',
            reading.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        return SensorReadingResult(reading: reading, isFromCache: false);
      }
    } catch (_) {
      // Jaringan tidak tersedia — ambil dari cache SQLite (hanya mobile)
      if (!kIsWeb) {
        final db = await _dbHelper.database;
        final maps = await db.query(
          'sensor_readings',
          where: 'farm_id = ?',
          whereArgs: [farmId],
          orderBy: 'timestamp DESC',
          limit: 1,
        );
        if (maps.isNotEmpty) {
          return SensorReadingResult(
            reading: SensorReading.fromMap(maps.first),
            isFromCache: true,
          );
        }
      }
    }
    return null;
  }

  /// Mengambil riwayat sensor dari API (default 1 jam, maksimum 168 jam).
  /// Jika offline, mengembalikan data cache SQLite lokal.
  Future<List<SensorReading>> fetchHistoryReadings(
    String farmId, {
    int hours = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/sensors/history/',
        queryParameters: {'farm_id': farmId, 'hours': hours},
      );
      if (response.statusCode == 200 && response.data is List) {
        final readings = (response.data as List)
            .map((x) => SensorReading.fromMap({
                  ...x as Map<String, dynamic>,
                  'farm_id': farmId,
                }))
            .toList();

        // Update batch cache SQLite (hanya di mobile)
        if (!kIsWeb) {
          final db = await _dbHelper.database;
          final batch = db.batch();
          for (final reading in readings) {
            batch.insert(
              'sensor_readings',
              reading.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        }
        return readings;
      }
    } catch (_) {
      // Offline — ambil dari cache SQLite (hanya mobile)
      if (!kIsWeb) {
        final db = await _dbHelper.database;
        final maps = await db.query(
          'sensor_readings',
          where: 'farm_id = ?',
          whereArgs: [farmId],
          orderBy: 'timestamp DESC',
        );
        return maps.map((x) => SensorReading.fromMap(x)).toList();
      }
    }
    return [];
  }
}
