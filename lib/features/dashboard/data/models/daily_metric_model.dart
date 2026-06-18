import 'package:isar/isar.dart';

part 'daily_metric_model.g.dart';

@collection
class DailyMetricModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String dateString; // Format: YYYY-MM-DD

  late int steps;
  late double calories;
  late double distanceKm;
  late int durationMinutes;

  @Index()
  late String syncStatus; // 'pending', 'syncing', 'synced', 'failed'
}