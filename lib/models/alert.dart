class Alert {
  final String id;
  final String farmId;
  final DateTime timestamp;
  final String parameter;
  final double value;
  final double threshold;
  final String urgency;
  final String actionText;
  final bool isRead;

  Alert({
    required this.id,
    required this.farmId,
    required this.timestamp,
    required this.parameter,
    required this.value,
    required this.threshold,
    required this.urgency,
    required this.actionText,
    required this.isRead,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farm_id': farmId,
      'timestamp': timestamp.toIso8601String(),
      'parameter': parameter,
      'value': value,
      'threshold': threshold,
      'urgency': urgency,
      'action_text': actionText,
      'is_read': isRead ? 1 : 0,
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'],
      farmId: map['farm_id'] ?? map['farm'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      parameter: map['parameter'],
      value: (map['value'] as num).toDouble(),
      threshold: (map['threshold'] as num).toDouble(),
      urgency: map['urgency'],
      actionText: map['action_text'] ?? '',
      isRead: map['is_read'] == 1 || map['is_read'] == true,
    );
  }
}
