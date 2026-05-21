/// Panduan tindakan berdasarkan kondisi kritis parameter kolam.
/// Sumber: SOP penanganan darurat budidaya Vannamei (KKP RI, 2023).
///
/// Fully offline — hardcoded, tidak butuh koneksi internet.
/// Gunakan [resolveAlertAction] untuk mendapatkan teks tindakan
/// berdasarkan parameter, urgency, dan nilai sensor.
library;

// ─── Mapping statis ────────────────────────────────────────────────────────────

const Map<String, String> alertActions = {
  'do_danger': 'Nyalakan semua aerator sekarang. Hentikan pemberian pakan.',
  'do_warning': 'Tambah aerasi. Kurangi pakan 30%.',
  'temp_danger': 'Kurangi pakan 50%. Tambah sirkulasi air jika memungkinkan.',
  'temp_warning': 'Kurangi pakan 20%. Pantau kondisi udang.',
  'ph_danger_high': 'Tambahkan dolomit sesuai dosis standar. Kurangi pakan.',
  'ph_danger_low': 'Lakukan penggantian air parsial 20–30%.',
  'ph_warning': 'Pantau pH setiap jam. Siapkan tindakan jika memburuk.',
  'sal_danger_low': 'Periksa sumber air masuk. Tunda pemberian pakan.',
  'sal_danger_high': 'Tambah air tawar secara bertahap.',
};

// ─── Resolver ─────────────────────────────────────────────────────────────────

/// Resolve teks tindakan dari [alertActions] berdasarkan [parameter], [urgency]
/// ('bahaya'/'waspada'), dan [value] (untuk membedakan high/low pada pH & sal).
///
/// Jika tidak ada yang cocok, kembalikan [fallback] (default string kosong).
String resolveAlertAction(
  String parameter,
  String urgency, {
  double? value,
  String fallback = '',
}) {
  final param = parameter.toLowerCase();
  final urg = urgency.toLowerCase();

  if (param == 'do') {
    return urg == 'bahaya'
        ? alertActions['do_danger']!
        : alertActions['do_warning']!;
  }

  if (param == 'temp') {
    return urg == 'bahaya'
        ? alertActions['temp_danger']!
        : alertActions['temp_warning']!;
  }

  if (param == 'ph') {
    if (urg == 'bahaya') {
      // pH bahaya_high: > 9.0 ; bahaya_low: < 7.0
      final high = value != null && value > 8.0;
      return high
          ? alertActions['ph_danger_high']!
          : alertActions['ph_danger_low']!;
    }
    return alertActions['ph_warning']!;
  }

  if (param == 'sal') {
    if (urg == 'bahaya') {
      // sal bahaya_low: < 5 ; bahaya_high: > 30
      final high = value != null && value > 17.5; // midpoint (5+30)/2
      return high
          ? alertActions['sal_danger_high']!
          : alertActions['sal_danger_low']!;
    }
    // waspada sal tidak ada key tersendiri — fallback ke low jika < 10
    final low = value != null && value < 17.5;
    return low
        ? alertActions['sal_danger_low']!
        : alertActions['sal_danger_high']!;
  }

  return fallback;
}
