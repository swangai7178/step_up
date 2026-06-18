import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:step_up_clone/core/database/local_database.dart';
import 'package:step_up_clone/features/dashboard/data/models/daily_metric_model.dart';

class StepLocalDatasource {
  final LocalDatabase _dbHelper = LocalDatabase();

  String _getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Fetches or initializes a clean database row tracking today's steps
  Future<DailyMetricModel> getOrCreateTodayMetrics() async {
    final db = await _dbHelper.database;
    final todayStr = _getTodayDateString();

    final List<Map<String, dynamic>> maps = await db.query(
      'daily_metrics',
      where: 'date_string = ?',
      whereArgs: [todayStr],
    );

    if (maps.isNotEmpty) {
      return DailyMetricModel.fromMap(maps.first);
    } else {
      final newDay = DailyMetricModel(
        dateString: todayStr,
        steps: 0,
        calories: 0.0,
        distanceKm: 0.0,
        durationMinutes: 0,
        syncStatus: 'pending',
      );
      await db.insert('daily_metrics', newDay.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      return newDay;
    }
  }

  /// Increments today's numerical rows using database upsert methods
  Future<void> updateTodayMetrics({
    required int additionalSteps,
    required double additionalCalories,
    required double additionalDistanceKm,
    required int additionalDurationMinutes,
  }) async {
    final db = await _dbHelper.database;
    final todayStr = _getTodayDateString();

    await db.rawUpdate('''
      UPDATE daily_metrics 
      SET steps = steps + ?, 
          calories = calories + ?, 
          distance_km = distance_km + ?, 
          duration_minutes = duration_minutes + ?,
          sync_status = 'pending'
      WHERE date_string = ?
    ''', [
      additionalSteps,
      additionalCalories,
      additionalDistanceKm,
      additionalDurationMinutes,
      todayStr
    ]);
  }

  /// Explicitly saves or updates an entire model record
  Future<void> saveMetrics(DailyMetricModel model) async {
    final db = await _dbHelper.database;
    await db.insert(
      'daily_metrics',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}