import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 ADD THIS IMPORT
import 'package:step_up_clone/core/services/sensor_service.dart';
import 'package:step_up_clone/features/dashboard/domain/entities/daily_metric.dart';
import 'package:step_up_clone/features/dashboard/domain/repositories/step_repository.dart';

class StepTrackerNotifier extends ChangeNotifier {
  final StepRepository _repository;
  final SensorService _sensorService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // 👈 Firestore instance

  DailyMetric? _currentMetrics;
  bool _isLoading = true;
  bool _isSyncing = false; // 👈 Track sync button state
  int? _sessionBaseline; 

  StepTrackerNotifier({
    required StepRepository repository,
    SensorService? sensorService,
  })  : _repository = repository,
        _sensorService = sensorService ?? SensorService();

  DailyMetric? get currentMetrics => _currentMetrics;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing; // 👈 Getter for UI spinner

  // 👇 NEW: Firebase Upload Logic
  Future<void> syncToFirebase() async {
    if (_currentMetrics == null || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // Assuming you track user sessions, change 'test_user' to your Auth UID later
      final userId = 'test_user'; 
      final dateKey = _currentMetrics!.dateString; // e.g., "2026-06-18"

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_metrics')
          .doc(dateKey)
          .set({
        'steps': _currentMetrics!.steps,
        'calories': _currentMetrics!.calories,
        'distanceKm': _currentMetrics!.distanceKm,
        'durationMinutes': _currentMetrics!.durationMinutes,
        'lastSyncedAt': FieldValue.serverTimestamp(),
        'isSynced': true,
      }, SetOptions(merge: true));

      print("☁️ Successfully uploaded steps to Firebase Cloud Firestore!");

      // Update local state repository marker to show synced checkmarks
      // If your repository has a markAsSynced method, call it here. 
      // For now, we will simulate it by manipulating the object reference or reloading:
      _currentMetrics = await _repository.getTodayMetrics(); 
    } catch (e) {
      print("❌ Firebase Sync Error: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

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
    if (_sessionBaseline == null) {
      _sessionBaseline = absoluteSteps;
    }
    
    final sessionSteps = absoluteSteps - _sessionBaseline!;

    try {
      await _repository.addSteps(sessionSteps);
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