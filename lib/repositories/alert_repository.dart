import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import '../models/alert.dart';
import '../core/network/dio_client.dart';
import '../core/local/database_helper.dart';

class AlertRepository {
  final Dio _dio = DioClient.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Ambil alert dari API; fallback SQLite saat offline (mobile only).
  Future<List<Alert>> fetchAlerts(String farmId) async {
    try {
      final response = await _dio.get(
        '/alerts/',
        queryParameters: {'farm_id': farmId},
      );
      if (response.statusCode == 200 && response.data is List) {
        final alerts = (response.data as List)
            .map((x) => Alert.fromMap({
                  ...x as Map<String, dynamic>,
                  'farm_id': farmId,
                }))
            .toList();

        // Cache ke SQLite (mobile only)
        if (!kIsWeb) {
          final db = await _dbHelper.database;
          final batch = db.batch();
          for (final alert in alerts) {
            batch.insert(
              'alerts',
              alert.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        }
        return alerts;
      }
    } catch (_) {
      // Fallback offline (mobile only)
    }

    if (!kIsWeb) {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'alerts',
        where: 'farm_id = ?',
        whereArgs: [farmId],
        orderBy: 'timestamp DESC',
        limit: 50,
      );
      return maps.map((x) => Alert.fromMap(x)).toList();
    }

    return [];
  }

  /// Tandai alert sebagai dibaca: update SQLite + PATCH ke API.
  Future<void> markAsRead(String alertId) async {
    if (!kIsWeb) {
      final db = await _dbHelper.database;
      await db.update(
        'alerts',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [alertId],
      );
    }

    try {
      await _dio.patch('/alerts/$alertId/read/');
    } catch (_) {
      // Offline — local sudah di-update
    }
  }
}
