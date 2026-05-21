import 'dart:convert';

class Recommendation {
  final String id;
  final String farmId;
  final DateTime timestamp;
  final double doLevel;
  final double temperature;
  final double salinity;
  final double ph;
  final int waterColor;
  final int shrimpCondition;
  final int appetite;
  final int weather;
  final int pondBottom;
  final int doc;
  final String mainAction;
  final List<String> actions;
  final String priority;
  final Map<String, dynamic> shapTop3;
  final String explanation;
  final double feedDoseKg;
  final double confidence;

  Recommendation({
    required this.id,
    required this.farmId,
    required this.timestamp,
    required this.doLevel,
    required this.temperature,
    required this.salinity,
    required this.ph,
    required this.waterColor,
    required this.shrimpCondition,
    required this.appetite,
    required this.weather,
    required this.pondBottom,
    required this.doc,
    required this.mainAction,
    required this.actions,
    required this.priority,
    required this.shapTop3,
    required this.explanation,
    required this.feedDoseKg,
    required this.confidence,
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
      'water_color': waterColor,
      'shrimp_condition': shrimpCondition,
      'appetite': appetite,
      'weather': weather,
      'pond_bottom': pondBottom,
      'doc': doc,
      'main_action': mainAction,
      'actions': jsonEncode(actions),
      'priority': priority,
      'shap_top3': jsonEncode(shapTop3),
      'explanation': explanation,
      'feed_dose_kg': feedDoseKg,
      'confidence': confidence,
    };
  }

  factory Recommendation.fromMap(Map<String, dynamic> map) {
    List<String> parseActions(dynamic act) {
      if (act is String) {
        return List<String>.from(jsonDecode(act));
      }
      return List<String>.from(act ?? []);
    }

    Map<String, dynamic> parseShap(dynamic sh) {
      if (sh is String) {
        return Map<String, dynamic>.from(jsonDecode(sh));
      }
      return Map<String, dynamic>.from(sh ?? {});
    }

    return Recommendation(
      id: map['id'],
      farmId: map['farm_id'] ?? map['farm'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      doLevel: (map['do_level'] as num).toDouble(),
      temperature: (map['temperature'] as num).toDouble(),
      salinity: (map['salinity'] as num).toDouble(),
      ph: (map['ph'] as num).toDouble(),
      waterColor: map['water_color'] as int,
      shrimpCondition: map['shrimp_condition'] as int,
      appetite: map['appetite'] as int,
      weather: map['weather'] as int,
      pondBottom: map['pond_bottom'] as int,
      doc: map['doc'] as int,
      mainAction: map['main_action'] ?? '',
      actions: parseActions(map['actions']),
      priority: map['priority'] ?? 'SEHAT',
      shapTop3: parseShap(map['shap_top3']),
      explanation: map['explanation'] ?? '',
      feedDoseKg: (map['feed_dose_kg'] as num).toDouble(),
      confidence: (map['confidence'] as num).toDouble(),
    );
  }
}
