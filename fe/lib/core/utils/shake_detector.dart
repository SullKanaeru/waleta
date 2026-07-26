import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  final VoidCallback onPhoneShake;
  final double shakeThresholdGravity;
  final int shakeSlopTimeMS;
  final int shakeCountResetTime;

  int _mShakeTimestamp = DateTime.now().millisecondsSinceEpoch;
  int _mShakeCount = 0;
  StreamSubscription? _streamSubscription;

  ShakeDetector({
    required this.onPhoneShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMS = 500,
    this.shakeCountResetTime = 3000,
  });

  void startListening() {
    _streamSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      double x = event.x;
      double y = event.y;
      double z = event.z;

      double gX = x / 9.80665;
      double gY = y / 9.80665;
      double gZ = z / 9.80665;

      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > shakeThresholdGravity) {
        var now = DateTime.now().millisecondsSinceEpoch;
        if (_mShakeTimestamp + shakeSlopTimeMS > now) {
          return;
        }

        if (_mShakeTimestamp + shakeCountResetTime < now) {
          _mShakeCount = 0;
        }

        _mShakeTimestamp = now;
        _mShakeCount++;

        if (kDebugMode) {
          print('Shake detected! Count: $_mShakeCount');
        }
        
        onPhoneShake();
      }
    });
  }

  void stopListening() {
    _streamSubscription?.cancel();
  }
}
