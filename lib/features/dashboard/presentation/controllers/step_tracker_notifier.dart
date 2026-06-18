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
  int? _initialSensorReading;

  StepTrackerNotifier({
    required this._repository,
    SensorService? sensorService,
  })  : _sensorService = sensorService ?? SensorService();

  // --- Getters for UI Consumption ---
  DailyMetric? get currentMetrics => _currentMetrics;
  bool get isLoading => _isLoading;

  /// Loads today's base record from storage and connects the hardware stream.
  Future<void> initializeTracker() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load or initialize today's data row locally
      _currentMetrics = await _repository.getTodayMetrics();
      _isLoading = false;
      notifyListeners();

      // 2. Establish connection to the hardware co-processor stream
      _sensorService.startListening(
        onStepsChanged: _handleHardwareStepUpdate,
      );
    } catch (e) {
      log('Notifier Initialization Failure: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handles incoming step events directly from the hardware sensors.
  void _handleHardwareStepUpdate(int absoluteSensorSteps) async {
    // Android hardware step counters return absolute steps taken since boot.
    // We isolate the step difference during the active app session.
    if (_initialSensorReading == null) {
      _initialSensorReading = absoluteSensorSteps;
      return;
    }

    final newStepsDetected = absoluteSensorSteps - _initialSensorReading!;
    if (newStepsDetected <= 0) return;

    // Reset baseline mark to keep increments precise
    _initialSensorReading = absoluteSensorSteps;

    try {
      // Update the local database layer with computed differentials
      await _repository.addSteps(newStepsDetected);

      // Re-read finalized local calculations to refresh presentation state
      _currentMetrics = await _repository.getTodayMetrics();
      notifyListeners();
    } catch (e) {
      log('Notifier failed to update step increments: $e');
    }
  }

  /// Terminate streams cleanly when UI is removed from the widget tree
  @override
  void dispose() {
    _sensorService.stopListening();
    super.dispose();
  }
}