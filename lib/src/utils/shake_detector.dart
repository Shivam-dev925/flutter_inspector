import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects shake gestures using device accelerometer
class ShakeDetector {
  final void Function() onShake;
  final int sensitivity;

  StreamSubscription? _subscription;
  DateTime? _lastShakeTime;
  double _lastX = 0;
  double _lastY = 0;
  double _lastZ = 0;

  static const int _shakeCooldownMs = 500;

  ShakeDetector({
    required this.onShake,
    this.sensitivity = 5,
  });

  /// Start listening for shake gestures
  void startListening() {
    _subscription = accelerometerEventStream().listen((event) {
      // Calculate acceleration differences from last reading
      final deltaX = (event.x - _lastX).abs();
      final deltaY = (event.y - _lastY).abs();
      final deltaZ = (event.z - _lastZ).abs();

      // Update last values
      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;

      // Calculate threshold based on sensitivity (1-10)
      // Higher sensitivity = lower threshold
      // Sensitivity 10: threshold ~5, Sensitivity 5: threshold ~10, Sensitivity 1: threshold ~18
      final threshold = 20.0 - (sensitivity * 1.5);

      // Detect shake on ANY axis
      final maxDelta = max(max(deltaX, deltaY), deltaZ);

      if (maxDelta > threshold) {
        final now = DateTime.now();
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!).inMilliseconds >
                _shakeCooldownMs) {
          _lastShakeTime = now;
          onShake();
        }
      }
    }, onError: (e) {
      // Sensor might not be available
    });
  }

  /// Stop listening for shake gestures
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Clean up resources
  void dispose() {
    stopListening();
  }
}
