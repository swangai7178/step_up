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
  Future<void> addSteps(int totalStepsToday) async {
    if (totalStepsToday <= 0) return;

    log('Saving TOTAL steps today: $totalStepsToday');

    final extraDistance =
        totalStepsToday * AppConstants.averageStrideLengthMeters / 1000.0;

    final extraCalories =
        totalStepsToday * AppConstants.caloriesBurnedPerStep;

    final extraMinutes = (totalStepsToday / 100).ceil();

    await _localDatasource.setTodayMetrics(
      steps: totalStepsToday,
      calories: extraCalories,
      distanceKm: extraDistance,
      durationMinutes: extraMinutes,
    );
  }

  @override
  Future<void> syncPastPendingDays() async {
    try {
      final model = await _localDatasource.getOrCreateTodayMetrics();

      if (model.syncStatus != 'synced') {
        await _remoteDatasource.uploadDailyMetrics(model);

        model.syncStatus = 'synced';
        await _localDatasource.saveMetrics(model);
      }
    } catch (e) {
      log('Sync failed: $e');
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