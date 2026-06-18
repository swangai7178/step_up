class DailyMetric {
  final String dateString; // Format: YYYY-MM-DD
  final int steps;
  final double calories;
  final double distanceKm;
  final int durationMinutes;
  final bool isSynced;

  const DailyMetric({
    required this.dateString,
    required this.steps,
    required this.calories,
    required this.distanceKm,
    required this.durationMinutes,
    required this.isSynced,
  });

  /// Computes the percentage progress toward a step goal.
  double getProgressPercentage(int stepGoal) {
    if (stepGoal <= 0) return 0.0;
    final progress = steps / stepGoal;
    return progress > 1.0 ? 1.0 : progress;
  }

  /// Convenience method to easily clone an entity with modified properties.
  DailyMetric copyWith({
    String? dateString,
    int? steps,
    double? calories,
    double? distanceKm,
    int? durationMinutes,
    bool? isSynced,
  }) {
    return DailyMetric(
      dateString: dateString ?? this.dateString,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}