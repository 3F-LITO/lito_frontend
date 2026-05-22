/// F2.3 — Indikator Tren Parameter
///
/// Membandingkan nilai sensor terbaru dengan bacaan ~30 menit lalu.
/// Threshold minimum berdasarkan presisi sensor dan variabilitas
/// natural tambak Vannamei.
library;

import '../models/sensor_data.dart';

enum SensorTrend { up, stable, down }

/// Threshold minimum perubahan yang dianggap signifikan.
const Map<String, double> trendThresholds = {
  'do': 0.3, // mg/L
  'temp': 0.5, // °C
  'sal': 0.5, // ppt
  'ph': 0.1, // unit
};

class TrendCalculator {
  /// Hitung tren berdasarkan delta dan threshold per-parameter.
  static SensorTrend getTrend(
    double current,
    double previous,
    double threshold,
  ) {
    final delta = current - previous;
    if (delta > threshold) return SensorTrend.up;
    if (delta < -threshold) return SensorTrend.down;
    return SensorTrend.stable;
  }

  /// Cari bacaan dari daftar riwayat yang paling mendekati [minutesAgo] menit
  /// yang lalu. Mengembalikan null jika history kosong atau semua entri
  /// terlalu jauh (lebih dari 2× window) dari target waktu.
  static SensorReading? findBaseline(
    List<SensorReading> history, {
    int minutesAgo = 30,
  }) {
    if (history.isEmpty) return null;

    final target = DateTime.now().subtract(Duration(minutes: minutesAgo));
    final maxDiff = Duration(minutes: minutesAgo * 2);

    SensorReading? best;
    Duration bestDiff = maxDiff + const Duration(seconds: 1);

    for (final r in history) {
      final diff = (r.timestamp.difference(target)).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = r;
      }
    }

    // Jika selisih terlalu jauh, anggap tidak ada baseline
    return bestDiff <= maxDiff ? best : null;
  }

  /// Helper: hitung tren untuk satu parameter dengan nama kunci [key].
  static SensorTrend trendFor(
    String key,
    double current,
    SensorReading? baseline,
  ) {
    if (baseline == null) return SensorTrend.stable;
    final prev = _valueFor(key, baseline);
    final threshold = trendThresholds[key] ?? 0.3;
    return getTrend(current, prev, threshold);
  }

  static double _valueFor(String key, SensorReading r) => switch (key) {
        'do' => r.doLevel,
        'temp' => r.temperature,
        'sal' => r.salinity,
        'ph' => r.ph,
        _ => 0,
      };
}
