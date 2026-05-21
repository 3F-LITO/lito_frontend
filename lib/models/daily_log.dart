import 'dart:convert';

class DailyLog {
  final String id;
  final String farmId;
  final DateTime date;
  final List<String> actions;
  final String notes;

  DailyLog({
    required this.id,
    required this.farmId,
    required this.date,
    required this.actions,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farm_id': farmId,
      'date': date.toIso8601String(),
      'actions': jsonEncode(actions),
      'notes': notes,
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    List<String> parseActions(dynamic act) {
      if (act is String) {
        return List<String>.from(jsonDecode(act));
      }
      return List<String>.from(act ?? []);
    }

    return DailyLog(
      id: map['id'],
      farmId: map['farm_id'] ?? map['farm'] ?? '',
      date: DateTime.parse(map['date']),
      actions: parseActions(map['actions']),
      notes: map['notes'] ?? '',
    );
  }
}