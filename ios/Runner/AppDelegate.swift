// ---------------------------
// File: LEOFindIt_iOS/ios/Runner/AppDelegate.swift
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
      let methodChannel = FlutterMethodChannel(
        name: "com.leofindit/bluetooth", binaryMessenger: controller.binaryMessenger)
      let eventChannel = FlutterEventChannel(
        name: "com.leofindit/bluetoothStream", binaryMessenger: controller.binaryMessenger)

      bluetoothManager = BluetoothManager()
      eventChannel.setStreamHandler(bluetoothManager)

      methodChannel.setMethodCallHandler { [weak self] call, result in
        guard let manager = self?.bluetoothManager else {
          result(
            FlutterError(
              code: "NO_MANAGER",
              message: "BluetoothManager not initialized",
              details: nil))
          return
        }

        switch call.method {
        case "startScan":
          manager.startScan()
          result("Scan started")
        case "stopScan":
          manager.stopScan()
          result("Scan stopped")
        case "makeItSing":
          if let args = call.arguments as? [String: Any],
            let id = args["id"] as? String
          {
            manager.makeItSing(deviceId: id)
            result("makeItSing sent to device \(id)")
          } else {
            result(
              FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Device ID not provided",
                details: nil))
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
  }
#endif
