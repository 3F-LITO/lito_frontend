class ApiConstants {
  // Port default Django adalah 8000
  // 10.0.2.2 = localhost dari Android emulator
  // Ganti dengan IP lokal (misal: 192.168.1.5) jika pakai HP fisik / Real Device
  static const baseUrl = 'http://10.0.2.2:8000/api/v1';

  static const recommend       = '/recommend/';
  static const simulation      = '/simulation/';
  static const alerts          = '/alerts/';
  static const farm            = '/farm/';
}
