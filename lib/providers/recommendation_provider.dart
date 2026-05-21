import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../repositories/recommendation_repository.dart';
import '../core/local/preferences.dart';

class RecommendationProvider extends ChangeNotifier {
  final RecommendationRepository _repository = RecommendationRepository();

  List<Recommendation> _history = [];
  bool _isLoading = false;

  List<Recommendation> get history => _history;
  bool get isLoading => _isLoading;

  /// Muat riwayat rekomendasi dari API / SQLite cache.
  Future<void> loadHistory() async {
    final farmId = Preferences.activeFarmId;
    if (farmId == null) return;

    _isLoading = true;
    notifyListeners();

    _history = await _repository.fetchHistory(farmId);

    _isLoading = false;
    notifyListeners();
  }
}
