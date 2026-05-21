import 'dart:math' show max;

/// Menghitung Pond Health Score (PHS) dari parameter sensor terbaru.
///
/// Formula dan bobot provisional berdasarkan:
///   - Boyd et al. (2020) — rentang optimal DO, suhu, pH
///   - Klinger & Naylor (2012) — rentang optimal salinitas
///   - Verdegem (2013) — DO paling kritis untuk kematian massal
///
/// CATATAN: Bobot (0.35, 0.25, 0.25, 0.15) bersifat provisional dan
/// HARUS diperbarui dengan nilai SHAP feature importance setelah model
/// selesai ditraining agar konsisten dengan klaim mekanisme ML.
class PondHealthCalculator {
  // ── Normalisasi per-parameter ────────────────────────────────────────────

  /// DO optimal: 5–8 mg/L (Boyd et al., 2020)
  static double _normalizeDO(double v) {
    if (v >= 5 && v <= 8) return 100;
    if (v >= 4 && v < 5) return 60 + (v - 4) * 40;
    if (v >= 3 && v < 4) return 20 + (v - 3) * 40;
    if (v < 3) return max(0, v / 3 * 20);
    return max(0, 100 - (v - 8) * 15); // di atas optimal
  }

  /// Suhu optimal: 23–30°C (Boyd et al., 2020)
  static double _normalizeTemp(double v) {
    if (v >= 23 && v <= 30) return 100;
    if (v >= 20 && v < 23) return 60 + (v - 20) * (40 / 3);
    if (v >= 30 && v <= 32) return 60 + (32 - v) * 20;
    if (v < 20) return max(0, v / 20 * 60);
    return max(0, 20 - (v - 32) * 10);
  }

  /// pH optimal: 7.5–8.5 (Boyd et al., 2020)
  static double _normalizePH(double v) {
    if (v >= 7.5 && v <= 8.5) return 100;
    if (v >= 7.0 && v < 7.5) return 40 + (v - 7.0) * 120;
    if (v > 8.5 && v <= 9.0) return 40 + (9.0 - v) * 120;
    return max(0, 40 - (7.0 - v).abs() * 30);
  }

  /// Salinitas optimal: 10–25 ppt (Klinger & Naylor, 2012)
  static double _normalizeSal(double v) {
    if (v >= 10 && v <= 25) return 100;
    if (v >= 5 && v < 10) return 50 + (v - 5) * 10;
    if (v > 25 && v <= 28) return 50 + (28 - v) * (50 / 3);
    return max(0, 50 - (10 - v).abs() * 8);
  }

  // ── Skor akhir ────────────────────────────────────────────────────────────

  static int calculateScore({
    required double doLevel,
    required double ph,
    required double temperature,
    required double salinity,
  }) {
    final score = (_normalizeDO(doLevel) * 0.35) +
        (_normalizePH(ph) * 0.25) +
        (_normalizeTemp(temperature) * 0.25) +
        (_normalizeSal(salinity) * 0.15);
    return score.clamp(0, 100).round();
  }

  /// Label kondisi berdasarkan skor.
  static PhsCategory categoryOf(int score) {
    if (score >= 80) return PhsCategory.healthy;
    if (score >= 50) return PhsCategory.needsAttention;
    return PhsCategory.critical;
  }
}

enum PhsCategory { healthy, needsAttention, critical }
