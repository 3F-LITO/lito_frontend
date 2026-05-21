class FeedLog {
  final String id;
  final String farmId;
  final DateTime timestamp;
  final double feedDoseKg;
  final String notes;

  FeedLog({
    required this.id,
    required this.farmId,
    required this.timestamp,
    required this.feedDoseKg,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farm_id': farmId,
      'timestamp': timestamp.toIso8601String(),
      'feed_dose_kg': feedDoseKg,
      'notes': notes,
    };
  }

  factory FeedLog.fromMap(Map<String, dynamic> map) {
    return FeedLog(
      id: map['id'],
      farmId: map['farm_id'] ?? map['farm'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      feedDoseKg: (map['feed_dose_kg'] as num).toDouble(),
      notes: map['notes'] ?? '',
    );
  }
}
