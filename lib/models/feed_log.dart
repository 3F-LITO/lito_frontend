class FeedLog {
  final String id;
  final String farmId;
  final DateTime timestamp;
  final double recommendedKg;  // dosis rekomendasi ML
  final double actualKg;        // realisasi aktual (F1.7)
  final double pricePerKg;      // harga pakan per kg (F1.7)
  final String notes;

  FeedLog({
    required this.id,
    required this.farmId,
    required this.timestamp,
    required this.recommendedKg,
    required this.actualKg,
    required this.pricePerKg,
    required this.notes,
  });

  /// Total biaya sesi ini (F1.8)
  double get totalCost => actualKg * pricePerKg;

  /// Alert overfeeding: aktual > rekomendasi + 20% (F1.9)
  bool get isOverfeeding => recommendedKg > 0 && actualKg > recommendedKg * 1.2;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farm_id': farmId,
      'timestamp': timestamp.toIso8601String(),
      'recommended_kg': recommendedKg,
      'actual_kg': actualKg,
      'price_per_kg': pricePerKg,
      'notes': notes,
    };
  }

  factory FeedLog.fromMap(Map<String, dynamic> map) {
    return FeedLog(
      id: map['id'],
      farmId: map['farm_id'] ?? map['farm'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      recommendedKg: (map['recommended_kg'] as num? ?? 0).toDouble(),
      actualKg: (map['actual_kg'] as num? ?? 0).toDouble(),
      pricePerKg: (map['price_per_kg'] as num? ?? 0).toDouble(),
      notes: map['notes'] ?? '',
    );
  }
}
