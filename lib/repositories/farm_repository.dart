import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/farm.dart';
import '../core/network/dio_client.dart';
import '../core/local/database_helper.dart';

class FarmRepository {
  final Dio _dio = DioClient.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const _uuid = Uuid();

  /// Ambil farm aktif: API dulu, fallback SQLite terbaru.
  Future<Farm?> fetchActiveFarm() async {
    try {
      final response = await _dio.get('/farms/');
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        if (list.isNotEmpty) {
          final farm = Farm.fromMap(list.first as Map<String, dynamic>);

          if (!kIsWeb) {
            final db = await _dbHelper.database;
            await db.insert(
              'farms',
              {...farm.toMap(), 'is_synced': 1},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          return farm;
        }
        // API mengembalikan list kosong → farm belum tersync, fall through ke SQLite
      }
    } catch (_) {}

    if (!kIsWeb) {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'farms',
        orderBy: 'created_at DESC',
        limit: 1,
      );
      if (maps.isNotEmpty) return Farm.fromMap(maps.first);
    }
    return null;
  }

  /// Buat farm baru: simpan ke SQLite dulu (is_synced=0), lalu POST API.
  /// Jika API berhasil, update is_synced=1 dan gunakan ID dari server.
  Future<Farm> createFarm({
    required String name,
    required double sizeM2,
    required String shrimpType,
    required DateTime stockingDate,
    required int stockingCount,
  }) async {
    final localId = _uuid.v4();
    final now = DateTime.now();
    final farm = Farm(
      id: localId,
      name: name,
      sizeM2: sizeM2,
      shrimpType: shrimpType,
      stockingDate: stockingDate,
      stockingCount: stockingCount,
      createdAt: now,
    );

    if (!kIsWeb) {
      final db = await _dbHelper.database;
      await db.insert(
        'farms',
        {...farm.toMap(), 'is_synced': 0},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    try {
      final response = await _dio.post('/farms/', data: {
        'name': name,
        'size_m2': sizeM2,
        'shrimp_type': shrimpType,
        'stocking_date': '${stockingDate.year.toString().padLeft(4, '0')}-'
            '${stockingDate.month.toString().padLeft(2, '0')}-'
            '${stockingDate.day.toString().padLeft(2, '0')}',
        'stocking_count': stockingCount,
      });

      if (response.statusCode == 201 && response.data != null) {
        final serverFarm = Farm.fromMap(response.data as Map<String, dynamic>);

        if (!kIsWeb) {
          final db = await _dbHelper.database;
          // Hapus local draft, simpan server version
          await db.delete('farms', where: 'id = ?', whereArgs: [localId]);
          await db.insert(
            'farms',
            {...serverFarm.toMap(), 'is_synced': 1},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        return serverFarm;
      }
    } catch (_) {
      // Offline — local draft tetap tersimpan, akan di-sync nanti
    }
    return farm;
  }

  /// Sync farm yang belum ter-sync ke server (is_synced=0).
  Future<void> syncPendingFarms() async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;
    final pending = await db.query(
      'farms',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    for (final row in pending) {
      try {
        final farm = Farm.fromMap(row);
        final stockingDate = farm.stockingDate;
        final response = await _dio.post('/farms/', data: {
          'name': farm.name,
          'size_m2': farm.sizeM2,
          'shrimp_type': farm.shrimpType,
          'stocking_date': '${stockingDate.year.toString().padLeft(4, '0')}-'
              '${stockingDate.month.toString().padLeft(2, '0')}-'
              '${stockingDate.day.toString().padLeft(2, '0')}',
          'stocking_count': farm.stockingCount,
        });
        if (response.statusCode == 201 && response.data != null) {
          final serverFarm =
              Farm.fromMap(response.data as Map<String, dynamic>);
          await db.delete('farms', where: 'id = ?', whereArgs: [farm.id]);
          await db.insert(
            'farms',
            {...serverFarm.toMap(), 'is_synced': 1},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } catch (_) {
        // Biarkan sampai online berikutnya
      }
    }
  }
}
