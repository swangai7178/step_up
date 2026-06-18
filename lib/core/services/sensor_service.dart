import 'dart:async';
import 'dart:developer';
import 'package:pedometer/pedometer.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<StepCount>? _stepCountSubscription;
  
  /// Callback execution hook that features can listen to for active updates
  void Function(int steps)? _onStepsChanged;

  /// Starts listening to live step modifications from the phone hardware.
  void startListening({required void Function(int steps) onStepsChanged}) {
    _onStepsChanged = onStepsChanged;
    
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _handleStepEvent,
      onError: _handleSensorError,
      cancelOnError: false,
    );
    
    log('Pedometer Hardware Stream connection established.');
  }

  void _handleStepEvent(StepCount event) {
    log('Hardware Pedometer update received: ${event.steps} absolute steps');
    if (_onStepsChanged != null) {
      _onStepsChanged!(event.steps);
    }
  }

  void _handleSensorError(Object error) {
    log('Hardware Step Counter Error or hardware unavailable: $error');
  }

  /// Clean teardown when view state lifecycle terminates
  void stopListening() {
    _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
    _onStepsChanged = null;
    log('Pedometer Hardware Stream disconnected.');
  }
}