import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:step_up_clone/core/database/local_database.dart';
import 'package:step_up_clone/features/dashboard/data/models/daily_metric_model.dart';

class StepLocalDatasource {
  final LocalDatabase _dbHelper = LocalDatabase();

  String _getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Fetch or create today's row
  Future<DailyMetricModel> getOrCreateTodayMetrics() async {
    final db = await _dbHelper.database;
    final todayStr = _getTodayDateString();

    final result = await db.query(
      'daily_metrics',
      where: 'date_string = ?',
      whereArgs: [todayStr],
    );

    if (result.isNotEmpty) {
      return DailyMetricModel.fromMap(result.first);
    }

    final newDay = DailyMetricModel(
      dateString: todayStr,
      steps: 0,
      calories: 0.0,
      distanceKm: 0.0,
      durationMinutes: 0,
      syncStatus: 'pending',
    );

    await db.insert(
      'daily_metrics',
      newDay.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return newDay;
  }

  /// ✅ FIXED: overwrite-based update (NOT increment)
  Future<void> setTodayMetrics({
    required int steps,
    required double calories,
    required double distanceKm,
    required int durationMinutes,
  }) async {
    final db = await _dbHelper.database;
    final todayStr = _getTodayDateString();

    await db.update(
      'daily_metrics',
      {
        'steps': steps,
        'calories': calories,
        'distance_km': distanceKm,
        'duration_minutes': durationMinutes,
        'sync_status': 'pending',
      },
      where: 'date_string = ?',
      whereArgs: [todayStr],
    );
  }

  /// Keep this for remote sync / manual override
  Future<void> saveMetrics(DailyMetricModel model) async {
    final db = await _dbHelper.database;

    await db.insert(
      'daily_metrics',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}