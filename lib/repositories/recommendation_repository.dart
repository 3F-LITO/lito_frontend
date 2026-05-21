import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../models/recommendation.dart';
import '../core/network/dio_client.dart';
import '../core/local/database_helper.dart';

class RecommendationRepository {
  final Dio _dio = DioClient.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Mengirim input parameter air + input kontekstual ke Django API untuk kalkulasi ML
  Future<Recommendation?> requestRecommendation(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post('/recommend', data: payload);
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final recommendation = Recommendation.fromMap(response.data);
        
        // Cache ke SQLite
        final db = await _dbHelper.database;
        await db.insert('recommendations', recommendation.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return recommendation;
      }
    } catch (e) {
      // Saat offline, kita tidak bisa memanggil ML predictor di backend Django.
      // Kita return null agar UI menampilkan error koneksi khusus.
    }
    return null;
  }

  // Mengambil riwayat rekomendasi pakan & stres dari SQLite/Django
  Future<List<Recommendation>> fetchHistory(String farmId) async {
    try {
      final response = await _dio.get('/recommendations/$farmId/');
      if (response.statusCode == 200 && response.data is List) {
        final recommendations = (response.data as List).map((x) => Recommendation.fromMap(x)).toList();
        
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var rec in recommendations) {
          batch.insert('recommendations', rec.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
        return recommendations;
      }
    } catch (e) {
      // Fallback offline
    }

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recommendations',
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((x) => Recommendation.fromMap(x)).toList();
  }
}
