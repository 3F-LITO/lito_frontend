class Thresholds {
  // Oksigen Terlarut (DO) - mg/L
  static const double minDoNormal = 5.0;
  static const double minDoCritical = 4.0;

  // Derajat Keasaman (pH)
  static const double minPhNormal = 7.5;
  static const double maxPhNormal = 8.5;
  static const double minPhCritical = 6.5;
  static const double maxPhCritical = 9.0;

  // Suhu Air - °C
  static const double minTempNormal = 28.0;
  static const double maxTempNormal = 31.0;
  static const double minTempCritical = 25.0;
  static const double maxTempCritical = 33.0;

  // Salinitas - ppt
  static const double minSalinityNormal = 15.0;
  static const double maxSalinityNormal = 25.0;
  static const double minSalinityCritical = 10.0;
  static const double maxSalinityCritical = 35.0;
}
