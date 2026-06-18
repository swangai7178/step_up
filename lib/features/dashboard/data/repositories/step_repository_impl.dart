import 'dart:developer';
import 'package:step_up_clone/core/constants/app_constants.dart';
import 'package:step_up_clone/features/dashboard/data/datasources/step_local_datasource.dart';
import 'package:step_up_clone/features/dashboard/data/datasources/step_remote_datasource.dart';
import 'package:step_up_clone/features/dashboard/data/models/daily_metric_model.dart';
import 'package:step_up_clone/features/dashboard/domain/entities/daily_metric.dart';
import 'package:step_up_clone/features/dashboard/domain/repositories/step_repository.dart';

class StepRepositoryImpl implements StepRepository {
  final StepLocalDatasource _localDatasource;
  final StepRemoteDatasource _remoteDatasource;

  StepRepositoryImpl({
    StepLocalDatasource? localDatasource,
    StepRemoteDatasource? remoteDatasource,
  })  : _localDatasource = localDatasource ?? StepLocalDatasource(),
        _remoteDatasource = remoteDatasource ?? StepRemoteDatasource();

  @override
  Future<DailyMetric> getTodayMetrics() async {
    final model = await _localDatasource.getOrCreateTodayMetrics();
    return _mapToEntity(model);
  }

  @override
  Future<void> addSteps(int count) async {
    if (count <= 0) return;

    final extraDistance = count * AppConstants.averageStrideLengthMeters / 1000.0;
    final extraCalories = count * AppConstants.caloriesBurnedPerStep;
    final extraMinutes = (count / 100).ceil();

    await _localDatasource.updateTodayMetrics(
      additionalSteps: count,
      additionalCalories: extraCalories,
      additionalDistanceKm: extraDistance,
      additionalDurationMinutes: extraMinutes,
    );
  }

  @override
  Future<void> syncPastPendingDays() async {
    try {
      // 1. Fetch today's record to check if it needs manual uploading
      final currentModel = await _localDatasource.getOrCreateTodayMetrics();
      
      // 2. Safely pass it to your remote datasource layer to satisfy the field usage cleanly
      if (currentModel.syncStatus == 'pending' || currentModel.syncStatus == 'failed') {
        await _remoteDatasource.uploadDailyMetrics(currentModel);
        
        // 3. Mark as synced locally if network operation succeeds
        currentModel.syncStatus = 'synced';
        await _localDatasource.saveMetrics(currentModel);
      }
    } catch (e) {
      log('Repository manual sync execution skipped or failed: $e');
    }
  }

  DailyMetric _mapToEntity(DailyMetricModel model) {
    return DailyMetric(
      dateString: model.dateString,
      steps: model.steps,
      calories: model.calories,
      distanceKm: model.distanceKm,
      durationMinutes: model.durationMinutes,
      isSynced: model.syncStatus == 'synced',
    );
  }
}