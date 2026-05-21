import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/farm.dart';
import '../core/network/dio_client.dart';

class FarmRepository {
  final Dio _dio = DioClient.instance;
  static const _uuid = Uuid();

  /// Ambil farm aktif: dari API.
  Future<Farm?> fetchActiveFarm() async {
    try {
      final response = await _dio.get('/farm/');
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        if (list.isNotEmpty) {
          return Farm.fromMap(list.first as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Ambil semua farm dari API.
  Future<List<Farm>> fetchAllFarms() async {
    try {
      final response = await _dio.get('/farm/');
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .map((e) => Farm.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Buat farm baru via API.
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

    try {
      final response = await _dio.post('/farm/', data: {
        'name': name,
        'size_m2': sizeM2,
        'shrimp_type': shrimpType,
        'stocking_date': '${stockingDate.year.toString().padLeft(4, '0')}-'
            '${stockingDate.month.toString().padLeft(2, '0')}-'
            '${stockingDate.day.toString().padLeft(2, '0')}',
        'stocking_count': stockingCount,
      });

      if (response.statusCode == 201 && response.data != null) {
        return Farm.fromMap(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return farm;
  }

  /// Sync tidak diperlukan — SQLite dihapus.
  Future<void> syncPendingFarms() async {}
}
