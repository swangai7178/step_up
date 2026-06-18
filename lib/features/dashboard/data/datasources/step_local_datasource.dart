import 'package:isar/isar.dart';
import 'package:step_up_clone/core/database/local_database.dart';
import 'package:step_up_clone/features/dashboard/data/models/daily_metric_model.dart';

class StepLocalDatasource {
  final LocalDatabase _db;

  StepLocalDatasource({LocalDatabase? db}) : _db = db ?? LocalDatabase();

  /// Formats the current date consistently to match database index expectations.
  String _getCurrentDateString() {
    return DateTime.now().toIso8601String().substring(0, 10);
  }

  /// Retrieves the metric record for the active calendar day.
  /// If no record exists, it creates, persists, and returns a baseline block.
  Future<DailyMetricModel> getOrCreateTodayMetrics() async {
    final isar = _db.instance;
    final todayStr = _getCurrentDateString();

    // Check for an existing record matching today's format string
    final existingRecord = await isar.dailyMetricModels
        .filter()
        .dateStringEqualTo(todayStr)
        .findFirst();

    if (existingRecord != null) {
      return existingRecord;
    }

    // Create a pristine default instance if the user opens the app for the first time today
    final newRecord = DailyMetricModel()
      ..dateString = todayStr
      ..steps = 0
      ..calories = 0.0
      ..distanceKm = 0.0
      ..durationMinutes = 0
      ..syncStatus = 'pending';

    await isar.writeTxn(() async {
      await isar.dailyMetricModels.put(newRecord);
    });

    return newRecord;
  }

  /// Atomically increments and updates today's rolling metric totals.
  Future<void> updateTodayMetrics({
    required int additionalSteps,
    required double additionalCalories,
    required double additionalDistanceKm,
    required int additionalDurationMinutes,
  }) async {
    final isar = _db.instance;
    final currentMetrics = await getOrCreateTodayMetrics();

    await isar.writeTxn(() async {
      currentMetrics.steps += additionalSteps;
      currentMetrics.calories += additionalCalories;
      currentMetrics.distanceKm += additionalDistanceKm;
      currentMetrics.durationMinutes += additionalDurationMinutes;
      
      // If data updates, make sure any previous failure states reset to pending
      if (currentMetrics.syncStatus == 'failed') {
        currentMetrics.syncStatus = 'pending';
      }

      await isar.dailyMetricModels.put(currentMetrics);
    });
  }

  /// Overwrites the exact parameters of today's model directly.
  /// Useful when synchronizing total historical offsets from a hardware sensor stream.
  Future<void> saveMetrics(DailyMetricModel model) async {
    final isar = _db.instance;
    await isar.writeTxn(() async {
      await isar.dailyMetricModels.put(model);
    });
  }
}