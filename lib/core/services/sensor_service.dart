import 'dart:async';
import 'dart:developer';
import 'package:pedometer/pedometer.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<StepCount>? _subscription;
  void Function(int steps)? _callback;

  void startListening({required void Function(int steps) onStepsChanged}) {
    _callback = onStepsChanged;

    _subscription?.cancel(); // 🔥 prevent duplicate streams

    _subscription = Pedometer.stepCountStream.listen(
      (event) {
        log('Pedometer raw: ${event.steps}');
        _callback?.call(event.steps);
      },
      onError: (error) {
        log('Pedometer error: $error');
      },
      cancelOnError: false,
    );

    log('Pedometer started');
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _callback = null;

    log('Pedometer stopped');
  }
}