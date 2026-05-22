import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/network/connectivity_service.dart';
import '../repositories/farm_repository.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _service = ConnectivityService();
  final FarmRepository _farmRepo = FarmRepository();
  bool _isOffline = false;
  StreamSubscription? _subscription;

  bool get isOffline => _isOffline;

  ConnectivityProvider() {
    _init();
  }

  void _init() async {
    // Cek koneksi awal saat inisiasi
    _isOffline = !await _service.isConnected;
    notifyListeners();

    // Dengarkan perubahan status koneksi secara real-time
    _subscription = _service.onConnectivityChanged.listen((resultList) {
      final wasOffline = _isOffline;
      _isOffline = resultList.contains(ConnectivityResult.none);
      notifyListeners();

      // Saat baru kembali online, sync data yang tertunda
      if (wasOffline && !_isOffline && !kIsWeb) {
        _farmRepo.syncPendingFarms();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
