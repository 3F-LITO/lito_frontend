import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../repositories/sensor_repository.dart';
import '../utils/trend_calculator.dart';

class SensorProvider extends ChangeNotifier {
  final SensorRepository _repository = SensorRepository();

  SensorReading? _latest;

  /// Bacaan ~30 menit lalu — digunakan untuk kalkulasi tren (F2.3).
  SensorReading? _baseline;

  /// Riwayat 1 jam — untuk sparkline di ParameterCardsGrid.
  List<SensorReading> _history = [];

  /// Riwayat 24 jam — untuk tabel ParameterHistoryScreen (F2.4).
  List<SensorReading> _history24h = [];
  bool _isLoading24h = false;

  bool _isLoading = false;
  bool _isOffline = false;

  Timer? _pollTimer;
  String? _activeFarmId;

  SensorReading? get latest => _latest;
  SensorReading? get baseline => _baseline;
  List<SensorReading> get history => _history;
  List<SensorReading> get history24h => _history24h;
  bool get isLoading => _isLoading;
  bool get isLoading24h => _isLoading24h;
  bool get isOffline => _isOffline;

  /// Mulai polling setiap 5 detik.
  void startPolling(String farmId) {
    _activeFarmId = farmId;
    _fetchLatest();
    _fetchHistory();
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _fetchLatest());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _fetchLatest() async {
    if (_activeFarmId == null) return;

    _isLoading = true;
    notifyListeners();

    final result = await _repository.fetchLatestReading(_activeFarmId!);

    if (result != null) {
      if (result.isFromCache) {
        _isOffline = true;
        // Saat offline, latest tetap dari cache; baseline tetap dari history
        _latest ??= result.reading;
      } else {
        _latest = result.reading;
        _isOffline = false;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchHistory() async {
    if (_activeFarmId == null) return;
    final readings =
        await _repository.fetchHistoryReadings(_activeFarmId!, hours: 1);
    _history = readings;

    // Update baseline: bacaan paling mendekati 30 menit lalu
    _baseline = TrendCalculator.findBaseline(_history, minutesAgo: 30);

    notifyListeners();
  }

  /// Muat riwayat 24 jam untuk halaman ParameterHistoryScreen (F2.4).
  Future<void> loadHistory24h() async {
    if (_activeFarmId == null) return;
    _isLoading24h = true;
    notifyListeners();

    _history24h = await _repository.fetchHistoryReadings(
      _activeFarmId!,
      hours: 24,
    );

    _isLoading24h = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
