import '../models/sensor_data.dart';

/// Tingkat urgensi kondisi kolam berdasarkan §3.2
/// (Boyd et al., 2020; Verdegem, 2013; Klinger & Naylor, 2012)
enum UrgencyLevel { aman, waspada, bahaya }

/// Hitung level urgensi dari [SensorReading] terkini.
/// Kembalikan [UrgencyLevel.aman] jika data null.
UrgencyLevel getUrgency(SensorReading? data) {
  if (data == null) return UrgencyLevel.aman;

  final bool isBahaya = data.doLevel < 3.0 ||
      data.temperature > 32.0 ||
      data.temperature < 20.0 ||
      data.ph < 7.0 ||
      data.ph > 9.0 ||
      data.salinity < 5.0 ||
      data.salinity > 30.0;

  final bool isWaspada = data.doLevel < 4.0 ||
      data.temperature > 30.0 ||
      data.ph < 7.5 ||
      data.ph > 8.5 ||
      data.salinity < 10.0 ||
      data.salinity > 25.0;

  if (isBahaya) return UrgencyLevel.bahaya;
  if (isWaspada) return UrgencyLevel.waspada;
  return UrgencyLevel.aman;
}

extension UrgencyLevelLabel on UrgencyLevel {
  String get label {
    switch (this) {
      case UrgencyLevel.bahaya:
        return 'BAHAYA';
      case UrgencyLevel.waspada:
        return 'WASPADA';
      case UrgencyLevel.aman:
        return 'AMAN';
    }
  }
}
