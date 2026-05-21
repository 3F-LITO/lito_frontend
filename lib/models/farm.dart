class Farm {
  final String id;
  final String name;
  final double sizeM2;
  final String shrimpType;
  final DateTime stockingDate;
  final int stockingCount;
  final DateTime createdAt;

  Farm({
    required this.id,
    required this.name,
    required this.sizeM2,
    required this.shrimpType,
    required this.stockingDate,
    required this.stockingCount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'size_m2': sizeM2,
      'shrimp_type': shrimpType,
      'stocking_date': stockingDate.toIso8601String(),
      'stocking_count': stockingCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      id: map['id'],
      name: map['name'],
      sizeM2: (map['size_m2'] as num).toDouble(),
      shrimpType: map['shrimp_type'],
      stockingDate: DateTime.parse(map['stocking_date']),
      stockingCount: map['stocking_count'] as int,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
