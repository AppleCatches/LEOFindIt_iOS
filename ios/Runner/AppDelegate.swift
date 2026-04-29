// ---------------------------
// leofindit/ios/Runner/AppDelegate.swift
// ---------------------------
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let CHANNEL = "leo_find_it/scanner"
  private var bluetoothManager: BluetoothManager?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

    // Create manager and give it the channel so it can push "onDevice" callbacks
    bluetoothManager = BluetoothManager(channel: channel)

    channel.setMethodCallHandler { [weak self] call, result in
      guard let manager = self?.bluetoothManager else {
        result(
          FlutterError(
            code: "NO_MANAGER", message: "BluetoothManager not initialized", details: nil))
        return
      }

      switch call.method {
      case "startScan":
        manager.startScan()
        result(true)
      case "stopScan":
        manager.stopScan()
        result(true)
      case "bluetoothState":
        result(manager.bluetoothStateString())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
