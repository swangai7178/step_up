

import 'package:step_up_clone/features/dashboard/domain/entities/daily_metric.dart';

abstract class StepRepository {
  
  /// Fetches or initializes the metric tracking block for the current day.
  Future<DailyMetric> getTodayMetrics();

  /// Increments today's metrics locally using incoming physical step readings.
  Future<void> addSteps(int count);

  /// Scans historical local database records to identify and upload 
  /// past completed days that failed to sync at midnight.
  Future<void> syncPastPendingDays();
}