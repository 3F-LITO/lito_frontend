// ─── Cycle Calculator ─────────────────────────────────────────────────────────
// Sumber formula:
//   - Boyd et al. (2020): fase pertumbuhan udang (Starter/Juvenil/Grower/Finisher)
//   - KKP RI (2023): durasi siklus standar Vannamei 100 hari, Windu 120 hari

/// Hitung DOC (Days of Culture) berdasarkan tanggal tebar.
/// Selalu dihitung fresh dari waktu saat ini — tidak perlu API.
int calculateDOC(DateTime stockingDate) {
  return DateTime.now().difference(stockingDate).inDays + 1;
}

/// Durasi siklus standar berdasarkan jenis udang (hari).
int cycleDuration(String shrimpType) => shrimpType == 'vannamei' ? 100 : 120;

/// Progress siklus 0.0–1.0 (di-clamp agar tidak melebihi 1).
double cycleProgress(int doc, String shrimpType) {
  return (doc / cycleDuration(shrimpType)).clamp(0.0, 1.0);
}

/// Label fase budidaya berdasarkan DOC (Boyd et al., 2020).
String getPhaseLabel(int doc) {
  if (doc <= 15) return 'Starter';
  if (doc <= 45) return 'Juvenil';
  if (doc <= 90) return 'Grower';
  return 'Finisher';
}

/// Estimasi berat rata-rata udang (gram) berdasarkan DOC.
/// Kurva pertumbuhan standar Vannamei intensif Indonesia.
/// Sumber: Boyd et al. (2020); FAO (2022) Technical Paper No. 564; JALA (2026).
double estimateWeight(int doc) {
  const growthTable = [
    // [doc_min, doc_max, berat_gram]
    [1, 7, 0.1],
    [8, 15, 0.3],
    [16, 25, 0.8],
    [26, 35, 1.5],
    [36, 45, 2.5],
    [46, 60, 4.5],
    [61, 75, 7.0],
    [76, 90, 10.0],
    [91, 110, 14.0],
    [111, 130, 18.0],
  ];

  for (final row in growthTable) {
    if (doc >= row[0] && doc <= row[1]) return row[2].toDouble();
  }
  return 0.1; // fallback DOC <1
}
