import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../repositories/recommendation_repository.dart';
import '../core/local/preferences.dart';

class RecommendationProvider extends ChangeNotifier {
  final RecommendationRepository _repository = RecommendationRepository();

  List<Recommendation> _history = [];
  Recommendation? _lastResult;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  // In-progress form data – cleared after successful submission
  Map<String, dynamic> _pendingContextual = {};
  Map<String, dynamic> _pendingParameters = {};

  List<Recommendation> get history => _history;
  Recommendation? get lastResult => _lastResult;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Map<String, dynamic> get pendingContextual => _pendingContextual;
  Map<String, dynamic> get pendingParameters => _pendingParameters;

  void setContextualData(Map<String, dynamic> data) {
    _pendingContextual = Map<String, dynamic>.from(data);
    notifyListeners();
  }

  void setParameterData(Map<String, dynamic> data) {
    _pendingParameters = Map<String, dynamic>.from(data);
    notifyListeners();
  }

  /// Submits contextual + parameter data to backend, saves result.
  /// Returns true on success.
  Future<bool> submitRecommendation(String farmId) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    // Default contextual values — fallback jika user skip contextual form
    // atau state reset karena page refresh di web.
    final defaultContextual = <String, dynamic>{
      'water_color': 0,
      'shrimp_condition': 0,
      'appetite': 0,
      'weather': 0,
      'pond_bottom': 0,
      'doc': 30,
    };

    final payload = <String, dynamic>{
      'farm_id': farmId,
      ...defaultContextual,
      ..._pendingContextual, // override dengan nilai aktual jika ada
      ..._pendingParameters,
    };

    final result = await _repository.requestRecommendation(payload);

    if (result != null) {
      _lastResult = result;
      _history.insert(0, result);
      _pendingContextual = {};
      _pendingParameters = {};
      _isSubmitting = false;
      notifyListeners();
      return true;
    } else {
      _error =
          'Gagal mendapatkan rekomendasi. Periksa koneksi internet dan pastikan backend berjalan.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

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
