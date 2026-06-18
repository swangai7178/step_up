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
  int? _sessionBaseline; 

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
    print("------------------------------------------------");
    print("🎯 NOTIFIER RECEIVED ABSOLUTE STEPS: $absoluteSteps");

    // Initialize baseline tracking token on application setup hook
    if (_sessionBaseline == null) {
      _sessionBaseline = absoluteSteps;
      print("🏁 INITIALIZED SESSION BASELINE TO: $_sessionBaseline");
    }
    
    final sessionSteps = absoluteSteps - _sessionBaseline!;
    print("📊 CALCULATED SESSION STEPS (Current - Baseline): $sessionSteps");
    print("------------------------------------------------");

    try {
      print("💾 PERSISTING TO REPOSITORY: $sessionSteps steps");
      await _repository.addSteps(sessionSteps);
      
      _currentMetrics = await _repository.getTodayMetrics();
      print("📈 REFRESHED METRICS IN UI. CURRENT TOTAL steps field: ${_currentMetrics?.steps ?? 0}");
      
      notifyListeners();
    } catch (e) {
      print("❌ ERROR DURING STEP UPDATE LOGIC: $e");
    }
  }

  @override
  void dispose() {
    _sensorService.stopListening();
    super.dispose();
  }
}