import 'dart:developer';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:step_up_clone/core/constants/app_constants.dart';
import 'package:step_up_clone/features/dashboard/data/models/daily_metric_model.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();

  factory LocalDatabase() {
    return _instance;
  }

  LocalDatabase._internal();

  bool _isInitialized = false;
  late final Isar _isarInstance;

  bool get isInitialized => _isInitialized;
  Isar get instance => _isarInstance;

  /// Open the Isar database connection instance.
  /// Works across both main UI and background background worker isolates.
  Future<void> initialize() async {
    if (_isInitialized) {
      log('Database already initialized.');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      
      _isarInstance = await Isar.open(
        [DailyMetricModelSchema],
        directory: dir.path,
        name: AppConstants.dbName,
      );

      _isInitialized = true;
      log('Local Database successfully initialized via Isar at: ${dir.path}');
    } catch (e) {
      log('Critical failure initializing Local Database: $e');
      rethrow;
    }
  }

  /// Safe closing routine for application lifecycle tracking
  Future<void> close() async {
    if (!_isInitialized) return;
    
    try {
      await _isarInstance.close();
      _isInitialized = false;
      log('Local Database connection closed cleanly.');
    } catch (e) {
      log('Error closing Local Database: $e');
    }
  }
}