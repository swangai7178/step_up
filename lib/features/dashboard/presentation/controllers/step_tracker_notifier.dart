import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:step_up_clone/core/services/sensor_service.dart';
import 'package:step_up_clone/features/dashboard/domain/entities/daily_metric.dart';
import 'package:step_up_clone/features/dashboard/domain/repositories/step_repository.dart';

class StepTrackerNotifier extends ChangeNotifier {
  final StepRepository _repository;
  final SensorService _sensorService;

  DailyMetric? _currentMetrics;
  bool _isLoading = true;

  int? _sessionBaseline; // 👈 FIXED: renamed for clarity

  StepTrackerNotifier({
    required StepRepository repository,
    SensorService? sensorService,
  })  : _repository = repository,
        _sensorService = sensorService ?? SensorService();

  DailyMetric? get currentMetrics => _currentMetrics;
  bool get isLoading => _isLoading;

  Future<void> initializeTracker() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentMetrics = await _repository.getTodayMetrics();

      _isLoading = false;
      notifyListeners();

      _sensorService.startListening(
        onStepsChanged: _handleHardwareStepUpdate,
      );
    } catch (e) {
      log('Initialization error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleHardwareStepUpdate(int absoluteSteps) async {
    log('RAW SENSOR STEPS: $absoluteSteps');

    // 🔥 FIX 1: baseline set ONLY ONCE
    _sessionBaseline ??= absoluteSteps;
    final todaySteps = absoluteSteps - _sessionBaseline!;

    if (todaySteps <= 0) return;

    log('TODAY STEPS CALCULATED: $todaySteps');

    try {
      // 🔥 FIX 2: we ALWAYS set total, NOT incremental delta confusion
      await _repository.addSteps(todaySteps);

      _currentMetrics = await _repository.getTodayMetrics();
      notifyListeners();
    } catch (e) {
      log('Step update error: $e');
    }
  }

  @override
  void dispose() {
    _sensorService.stopListening();
    super.dispose();
  }
}