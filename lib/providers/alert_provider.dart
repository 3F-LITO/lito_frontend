import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../repositories/alert_repository.dart';
import '../core/local/preferences.dart';

class AlertProvider extends ChangeNotifier {
  final AlertRepository _repository = AlertRepository();

  List<Alert> _alerts = [];
  bool _isLoading = false;
  Timer? _pollTimer;
  bool _disposed = false;

  /// Semua alert (terbaru pertama).
  List<Alert> get alerts => _alerts;

  /// Alert bahaya/waspada yang belum dibaca — ditampilkan di banner.
  List<Alert> get activeAlerts => _alerts.where((a) => !a.isRead).toList();

  /// Alert paling kritis yang belum dibaca (untuk banner utama).
  Alert? get topAlert {
    final danger = activeAlerts.where((a) => a.urgency == 'bahaya').toList();
    if (danger.isNotEmpty) return danger.first;
    return activeAlerts.isNotEmpty ? activeAlerts.first : null;
  }

  bool get isLoading => _isLoading;

  /// Mulai polling alert setiap 5 detik (selaras dengan sensor polling).
  void startPolling() {
    final farmId = Preferences.activeFarmId;
    if (farmId == null) return;
    _loadAlerts(farmId);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadAlerts(farmId),
    );
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _loadAlerts(String farmId) async {
    _isLoading = true;
    if (!_disposed) notifyListeners();

    _alerts = await _repository.fetchAlerts(farmId);

    _isLoading = false;
    if (!_disposed) notifyListeners();
  }

  /// Tandai alert sebagai dibaca — update lokal dulu, lalu sync ke API.
  Future<void> markAsRead(String alertId) async {
    // Optimistic update
    _alerts = _alerts.map((a) {
      return a.id == alertId
          ? Alert(
              id: a.id,
              farmId: a.farmId,
              timestamp: a.timestamp,
              parameter: a.parameter,
              value: a.value,
              threshold: a.threshold,
              urgency: a.urgency,
              actionText: a.actionText,
              isRead: true,
            )
          : a;
    }).toList();
    if (!_disposed) notifyListeners();

    await _repository.markAsRead(alertId);
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}
