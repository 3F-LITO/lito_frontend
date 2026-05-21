// class Alert(models.Model):
//     id = models.UUIDField(primary_key=True, default=uuid4)
//     farm = models.ForeignKey(Farm, on_delete=models.CASCADE)
//     timestamp = models.DateTimeField(auto_now_add=True)
//     parameter = models.CharField(max_length=20)
//     value = models.FloatField()
//     urgency = models.CharField(max_length=10)
//     action_text = models.TextField()
//     is_read = models.BooleanField(default=False)

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
      'farmId': farmId,
      'timestamp': timestamp.toIso8601String(),
      'parameter': parameter,
      'value': value,
      'threshold': threshold,
      'urgency': urgency,
      'actionText': actionText,
      'isRead': isRead ? 1 : 0, 
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'],
      farmId: map['farmId'] ?? map['farm_id'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      parameter: map['parameter'],
      value: (map['value'] as num).toDouble(),
      threshold: (map['threshold'] as num).toDouble(),
      urgency: map['urgency'],
      actionText: map['actionText'] ?? '',
      isRead: map['isRead'] == 1 || map['is_read'] == true, 
    );
  }
}