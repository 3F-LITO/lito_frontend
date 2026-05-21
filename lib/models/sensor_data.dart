class SensorReading {
  final String id;
  final String farmId;
  final DateTime timestamp;
  final double doLevel;
  final double temperature;
  final double salinity;
  final double ph;
  final bool isSimulated;

  SensorReading({
    required this.id,
    required this.farmId,
    required this.timestamp,
    required this.doLevel,
    required this.temperature,
    required this.salinity,
    required this.ph,
    required this.isSimulated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farm_id': farmId,
      'timestamp': timestamp.toIso8601String(),
      'do_level': doLevel,
      'temperature': temperature,
      'salinity': salinity,
      'ph': ph,
      'is_simulated': isSimulated ? 1 : 0,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'],
      farmId: map['farm_id'] ?? map['farm'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      doLevel: (map['do_level'] as num).toDouble(),
      temperature: (map['temperature'] as num).toDouble(),
      salinity: (map['salinity'] as num).toDouble(),
      ph: (map['ph'] as num).toDouble(),
      isSimulated: map['is_simulated'] == 1 || map['is_simulated'] == true,
    );
  }
}
