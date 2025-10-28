// ---------------------------
// File: ios/Runner/BluetoothManager.swift
// ---------------------------
import Foundation
import CoreBluetooth
import Flutter

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, FlutterStreamHandler {
  private var centralManager: CBCentralManager!
  private var eventSink: FlutterEventSink?

  override init() {
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }

  func startScan() {
    if centralManager.state == .poweredOn {
      centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
  }

  func stopScan() {
    centralManager.stopScan()
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    // Handle Bluetooth state updates
  }

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                      advertisementData: [String : Any], rssi RSSI: NSNumber) {
    let device: [String: Any] = [
      "name": peripheral.name ?? "Unknown",
      "id": peripheral.identifier.uuidString,
      "rssi": RSSI
    ]
    eventSink?(device)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
