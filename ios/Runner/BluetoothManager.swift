// ---------------------------
// File: LEOFindIt_iOS/ios/Runner/BluetoothManager.swift
// ---------------------------
import CoreBluetooth
import Foundation

#if canImport(Flutter)
  import Flutter
#else
  public typealias FlutterEventSink = (Any?) -> Void

  public class FlutterError: Error {
    public var code: String?
    public var message: String?
    public var details: Any?

    public init(_ code: String? = nil, _ message: String? = nil, _ details: Any? = nil) {
      self.code = code
      self.message = message
      self.details = details
    }
  }

  public protocol FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
      -> FlutterError?
    func onCancel(withArguments arguments: Any?) -> FlutterError?
  }
#endif

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate,
  FlutterStreamHandler
{
  private var centralManager: CBCentralManager!
  private var eventSink: FlutterEventSink?
  private var peripherals: [UUID: CBPeripheral] = [:]
  private var wantsScan: Bool = false

  override init() {
    super.init()
    centralManager = CBCentralManager(
      delegate: self,
      queue: nil,
      options: [CBCentralManagerOptionShowPowerAlertKey: true]
    )
  }

  // PUBLIC API FOR FLUTTER

  func startScan() {
    wantsScan = true

    if centralManager.state == .poweredOn {
      // discover any BLE devices
      centralManager.scanForPeripherals(
        withServices: nil,
        options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    // else {
    // Bluetooth not available
    // }
  }

  func stopScan() {
    wantsScan = false
    centralManager.stopScan()
  }

  func makeItSing(deviceId: String) {
    // attempt to connect and make the device emit a sound
    // implementation depends on the specific device and its services/characteristics
    guard let uuid = UUID(uuidString: deviceId),
      let peripheral = peripherals[uuid]
    else {
      return
    }
    centralManager.connect(peripheral, options: nil)
    // Further implementation would be needed to discover services and write to characteristics
  }

  // CBCentralManagerDelegate METHODS

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    // Handle Bluetooth state updates
    switch central.state {
    case .poweredOn:
      if wantsScan {
        central.scanForPeripherals(
          withServices: nil,
          options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
      }
    default:
      central.stopScan()
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {

    peripherals[peripheral.identifier] = peripheral
    let name = peripheral.name ?? "Unknown"
    let device: [String: Any] = [
      "name": name,
      "id": peripheral.identifier.uuidString,
      "rssi": RSSI.intValue,
    ]
    eventSink?(device)
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices(nil)
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard error == nil else { return }
    peripheral.services?.forEach { service in
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    guard error == nil else { return }
    // Here you would write to the characteristic that makes the device emit a sound
    // This is device-specific and requires knowledge of the device's GATT profile
  }

  // FlutterStreamHandler METHODS

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  )
    -> FlutterError?
  {
    self.eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?)
    -> FlutterError?
  {
    eventSink = nil
    return nil
  }
}
