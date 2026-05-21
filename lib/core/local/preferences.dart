import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static SharedPreferences? _prefs;

  // Inisialisasi awal SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Menyimpan status onboarding
  static Future<bool> setOnboarded(bool value) async {
    await init();
    return await _prefs!.setBool('is_onboarded', value);
  }

  // Membaca status onboarding
  static bool get isOnboarded {
    if (_prefs == null) return false;
    return _prefs!.getBool('is_onboarded') ?? false;
  }

  // Menyimpan ID kolam/tambak aktif saat ini
  static Future<bool> setActiveFarmId(String farmId) async {
    await init();
    return await _prefs!.setString('active_farm_id', farmId);
  }

  // Membaca ID kolam/tambak aktif saat ini
  static String? get activeFarmId {
    if (_prefs == null) return null;
    return _prefs!.getString('active_farm_id');
  }

  // Menghapus data preferensi lokal
  static Future<void> clear() async {
    await init();
    await _prefs!.clear();
  }
}
