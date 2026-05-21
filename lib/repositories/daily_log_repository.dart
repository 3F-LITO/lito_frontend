import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_log.dart';
import '../core/network/dio_client.dart';
import '../core/local/database_helper.dart';

class DailyLogRepository {
  final Dio _dio = DioClient.instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Submit catatan harian.
  /// - Online: POST ke /api/v1/daily-logs/, simpan ke SQLite (is_synced=1).
  /// - Offline: simpan ke SQLite dengan is_synced=0 untuk di-sync kemudian.
  Future<DailyLog?> submitLog({
    required String farmId,
    required List<String> actions,
    required String notes,
  }) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final response = await _dio.post('/daily-logs/', data: {
        'farm_id': farmId,
        'date': dateStr,
        'actions': actions,
        'notes': notes,
      });

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final log = DailyLog.fromMap({
          ...response.data as Map<String, dynamic>,
          'farm_id': farmId,
        });

        if (!kIsWeb) {
          await _saveToCache(log, isSynced: true);
        }
        return log;
      }
    } catch (_) {
      // Offline — simpan ke antrian lokal
      if (!kIsWeb) {
        final tempId = const Uuid().v4();
        final log = DailyLog(
          id: tempId,
          farmId: farmId,
          date: today,
          actions: actions,
          notes: notes,
        );
        await _saveToCache(log, isSynced: false);
        return log;
      }
    }
    return null;
  }

  Future<void> _saveToCache(DailyLog log, {required bool isSynced}) async {
    final db = await _db.database;
    await db.insert(
      'daily_logs',
      {
        'id': log.id,
        'farm_id': log.farmId,
        'date': log.date.toIso8601String(),
        'actions': jsonEncode(log.actions),
        'notes': log.notes,
        'is_synced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Sinkronisasi semua catatan yang belum tersync (is_synced=0).
  Future<void> syncPendingLogs() async {
    if (kIsWeb) return;
    final db = await _db.database;
    final pending = await db.query(
      'daily_logs',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    for (final row in pending) {
      try {
        final actions = List<String>.from(jsonDecode(row['actions'] as String));
        final resp = await _dio.post('/daily-logs/', data: {
          'farm_id': row['farm_id'],
          'date': (row['date'] as String).substring(0, 10),
          'actions': actions,
          'notes': row['notes'],
        });
        if (resp.statusCode == 201 || resp.statusCode == 200) {
          await db.update(
            'daily_logs',
            {'is_synced': 1},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      } catch (_) {
        // Biarkan — coba lagi nanti
      }
    }
  }
}
