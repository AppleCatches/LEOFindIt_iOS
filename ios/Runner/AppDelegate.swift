// ---------------------------
// File: ios/Runner/AppDelegate.swift
// ---------------------------
#if canImport(UIKit)
import UIKit
import Flutter
import CoreBluetooth

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  var bluetoothManager: BluetoothManager?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.leofindit/bluetooth", binaryMessenger: controller.binaryMessenger)
    let eventChannel = FlutterEventChannel(name: "com.leofindit/bluetoothStream", binaryMessenger: controller.binaryMessenger)

    bluetoothManager = BluetoothManager()
    eventChannel.setStreamHandler(bluetoothManager)

    channel.setMethodCallHandler { [weak self] call, result in
      guard let manager = self?.bluetoothManager else { return }
      switch call.method {
      case "startScan":
        manager.startScan()
        result("Scan started")
      case "stopScan":
        manager.stopScan()
        result("Scan stopped")
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
#endif
