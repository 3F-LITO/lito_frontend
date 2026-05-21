import 'package:dio/dio.dart';
import '../models/alert.dart';
import '../core/network/dio_client.dart';

class AlertRepository {
  final Dio _dio = DioClient.instance;

  /// Ambil alert dari API.
  Future<List<Alert>> fetchAlerts(String farmId) async {
    try {
      final response = await _dio.get(
        '/alerts',
        queryParameters: {'farm_id': farmId},
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((x) => Alert.fromMap({
                  ...x as Map<String, dynamic>,
                  'farm_id': farmId,
                }))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Tandai alert sebagai dibaca: PATCH ke API.
  Future<void> markAsRead(String alertId) async {
    try {
      await _dio.post('/alerts/$alertId/read/');
    } catch (_) {}
  }
}
