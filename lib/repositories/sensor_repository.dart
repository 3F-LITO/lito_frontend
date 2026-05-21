import 'package:dio/dio.dart';
import '../models/sensor_data.dart';
import '../core/network/dio_client.dart';

/// Hasil fetch sensor beserta informasi asal data (jaringan atau cache).
class SensorReadingResult {
  final SensorReading reading;
  final bool isFromCache;

  const SensorReadingResult({required this.reading, required this.isFromCache});
}

class SensorRepository {
  final Dio _dio = DioClient.instance;

  /// Mengambil bacaan sensor terakhir dari API.
  Future<SensorReadingResult?> fetchLatestReading(String farmId) async {
    try {
      final response = await _dio.get(
        '/simulation/latest',
        queryParameters: {'farm_id': farmId},
      );
      if (response.statusCode == 200 && response.data != null) {
        final reading = SensorReading.fromMap({
          ...response.data as Map<String, dynamic>,
          'farm_id': farmId,
        });
        return SensorReadingResult(reading: reading, isFromCache: false);
      }
    } catch (_) {}
    return null;
  }

  /// Mengambil riwayat sensor dari API (default 1 jam, maksimum 168 jam).
  Future<List<SensorReading>> fetchHistoryReadings(
    String farmId, {
    int hours = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/simulation/history',
        queryParameters: {'farm_id': farmId, 'hours': hours},
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((x) => SensorReading.fromMap({
                  ...x as Map<String, dynamic>,
                  'farm_id': farmId,
                }))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
