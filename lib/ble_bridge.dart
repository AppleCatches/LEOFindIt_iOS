import 'dart:async';
import 'package:flutter/services.dart';
import 'models.dart';

// Bridge to native BLE scanning code
class BleBridge {
  static const MethodChannel _ch = MethodChannel("leo_find_it/scanner");

  static final StreamController<TrackerDevice> _controller =
      StreamController<TrackerDevice>.broadcast();
  static bool _attached = false;
  static bool _isScanning = false;

  static Stream<TrackerDevice> get detections {
    _attachOnce();
    return _controller.stream;
  }

  // Indicates whether a BLE scan is currently active
  static bool get isScanning => _isScanning;

  static void _attachOnce() {
    if (_attached) return;
    _attached = true;

    _ch.setMethodCallHandler((call) async {
      if (call.method == "onDevice") {
        final data = Map<String, dynamic>.from(call.arguments as Map);
        _controller.add(TrackerDevice.fromNative(data));
      }
    });
  }

  // Start BLE scanning by invoking the native method
  // Update the scanning state based on the result
  static Future<bool> startScan() async {
    _attachOnce();
    final ok = await _ch.invokeMethod<bool>("startScan") ?? false;
    _isScanning = ok;
    return ok;
  }

  // Stop BLE scanning by invoking the native method
  // Update the scanning state accordingly
  static Future<String> bluetoothState() async {
    final state = await _ch.invokeMethod<String>("bluetoothState");
    return state ?? "unknown";
  }

  static Future<void> stopScan() async {
    try {
      await _ch.invokeMethod("stopScan");
    } catch (_) {
    } finally {
      _isScanning = false;
    }
  }
}
