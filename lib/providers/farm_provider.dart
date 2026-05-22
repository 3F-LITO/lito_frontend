import 'package:flutter/material.dart';
import '../models/farm.dart';
import '../repositories/farm_repository.dart';
import '../core/local/preferences.dart';

class FarmProvider extends ChangeNotifier {
  final FarmRepository _repo = FarmRepository();

  Farm? _currentFarm;
  List<Farm> _allFarms = [];
  bool _isLoading = false;
  String? _error;

  Farm? get currentFarm => _currentFarm;
  List<Farm> get allFarms => _allFarms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Muat semua farm dari server/SQLite (untuk picker di onboarding).
  Future<void> loadAllFarms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    _allFarms = await _repo.fetchAllFarms();
    _isLoading = false;
    notifyListeners();
  }

  /// Pilih farm yang sudah ada sebagai farm aktif.
  Future<void> selectFarm(Farm farm) async {
    _currentFarm = farm;
    await Preferences.setActiveFarmId(farm.id);
    notifyListeners();
  }

  /// Muat data farm aktif dari server/SQLite.
  /// Skip jika sudah ada di memory — hindari overwrite saat tab switch.
  Future<void> loadCurrentFarm() async {
    if (_currentFarm != null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final preferredFarmId = Preferences.activeFarmId;

    // Prioritas: farm yang dipilih user terakhir (activeFarmId)
    if (preferredFarmId != null && preferredFarmId.isNotEmpty) {
      final farms = await _repo.fetchAllFarms();
      if (farms.isNotEmpty) {
        _allFarms = farms;
        for (final farm in farms) {
          if (farm.id == preferredFarmId) {
            _currentFarm = farm;
            break;
          }
        }
      }
    }

    // Fallback: farm terbaru dari API jika activeFarmId tidak ditemukan
    _currentFarm ??= await _repo.fetchActiveFarm();

    // Simpan farm ID ke preferences agar dipakai provider lain
    if (_currentFarm != null) {
      await Preferences.setActiveFarmId(_currentFarm!.id);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Buat siklus baru. Kembalikan true jika berhasil.
  Future<bool> createFarm({
    required String name,
    required double sizeM2,
    required String shrimpType,
    required DateTime stockingDate,
    required int stockingCount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final farm = await _repo.createFarm(
        name: name,
        sizeM2: sizeM2,
        shrimpType: shrimpType,
        stockingDate: stockingDate,
        stockingCount: stockingCount,
      );
      _currentFarm = farm;
      await Preferences.setActiveFarmId(farm.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset siklus — hapus farm aktif dari state (data lama tetap di DB lama).
  /// Form input baru akan membuat farm baru.
  void resetCycle() {
    _currentFarm = null;
    notifyListeners();
  }
}
