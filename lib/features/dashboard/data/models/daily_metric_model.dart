
class DailyMetricModel {
  final String dateString;
  int steps;
  double calories;
  double distanceKm;
  int durationMinutes;
  String syncStatus;

  DailyMetricModel({
    required this.dateString,
    required this.steps,
    required this.calories,
    required this.distanceKm,
    required this.durationMinutes,
    required this.syncStatus,
  });

  /// Factory constructor to parse rows from SQLite results cleanly
  factory DailyMetricModel.fromMap(Map<String, dynamic> map) {
    return DailyMetricModel(
      dateString: map['date_string'] as String,
      steps: map['steps'] as int,
      calories: (map['calories'] as num).toDouble(),
      distanceKm: (map['distance_km'] as num).toDouble(),
      durationMinutes: map['duration_minutes'] as int,
      syncStatus: map['sync_status'] as String,
    );
  }

  /// Converts the current instance into a readable map database row block
  Map<String, dynamic> toMap() {
    return {
      'date_string': dateString,
      'steps': steps,
      'calories': calories,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'sync_status': syncStatus,
    };
  }
}