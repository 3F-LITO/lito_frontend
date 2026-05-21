import 'package:dio/dio.dart';
import '../models/recommendation.dart';
import '../core/network/dio_client.dart';

class RecommendationRepository {
  final Dio _dio = DioClient.instance;

  Future<Recommendation?> requestRecommendation(
      Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post('/recommend', data: payload);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return Recommendation.fromMap(response.data);
      }
    } on DioException catch (e) {
      print(
          '[RecommendationRepo] HTTP ${e.response?.statusCode}: ${e.response?.data}');
      print('[RecommendationRepo] Payload: $payload');
    } catch (e) {
      print('[RecommendationRepo] Error: $e');
    }
    return null;
  }

  Future<List<Recommendation>> fetchHistory(String farmId) async {
    try {
      final response = await _dio.get('/recommendations/$farmId/');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((x) => Recommendation.fromMap(x))
            .toList();
      }
    } catch (e) {}
    return [];
  }
}
