import 'dart:async';
import 'package:flutter/services.dart';

class SensorService {
  static const EventChannel _channel = EventChannel('step_counter_channel');
  StreamSubscription? _subscription;
  void Function(int steps)? _callback;

  void startListening({required void Function(int steps) onStepsChanged}) {
    _callback = onStepsChanged;

    _subscription = _channel.receiveBroadcastStream().listen(
      (event) {
        final steps = event as int;
        
        // HIGH VISIBILITY LOG
        print("📥 DART SENSOR_SERVICE RECEIVED: $steps");
        
        _callback?.call(steps);
      },
      onError: (error) {
        print("❌ Sensor Stream Error: $error");
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}