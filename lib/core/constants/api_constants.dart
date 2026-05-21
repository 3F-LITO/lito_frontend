import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Web (Chrome): localhost:8000
  // Android emulator: 10.0.2.2:8000
  // HP fisik / Real Device: ganti dengan IP lokal (misal: 192.168.1.5)
  static String get baseUrl => kIsWeb
      ? 'http://localhost:8000/api/v1'
      : 'http://10.0.2.2:8000/api/v1';

  static const recommend       = '/recommend/';
  static const simulation      = '/simulation/';
  static const alerts          = '/alerts/';
  static const farm            = '/farm/';
  static const recommendations = '/recommendations/';
  static const feedLog         = '/feed-log/';
}
