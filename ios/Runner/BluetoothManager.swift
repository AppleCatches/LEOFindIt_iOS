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

// Tracker Stats for Indirect AirTag Detection

private struct TrackerStats {
  var firstSeen: Date
  var lastSeen: Date
  var rssiSamples: [Int]
  var isConnectable: Bool
}

class BluetoothManager: NSObject,
  CBCentralManagerDelegate,
  CBPeripheralDelegate,
  FlutterStreamHandler
{

  private var centralManager: CBCentralManager!
  private var eventSink: FlutterEventSink?

  private var peripherals: [UUID: CBPeripheral] = [:]
  private var trackerStats: [UUID: TrackerStats] = [:]

  private var wantsScan: Bool = false

  override init() {
    super.init()
    centralManager = CBCentralManager(
      delegate: self,
      queue: nil,
      options: [CBCentralManagerOptionShowPowerAlertKey: true]
    )
  }

  // Public API Exposed to Flutter

  func startScan() {
    wantsScan = true

    // Start scan only when user presses Start.
    // If Bluetooth isn't ready, do NOT auto-start later.
    if centralManager.state != .poweredOn {
      print("Bluetooth not powered on — cannot start scan.")
      eventSink?(["type": "error", "code": "bluetooth_not_ready"])
      return
    }

    centralManager.scanForPeripherals(
      withServices: nil,
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
    )
    print("BLE scan started")
  }

  func stopScan() {
    wantsScan = false
    centralManager.stopScan()
    print("BLE scan stopped")
  }

  func makeItSing(deviceId: String) {
    guard let uuid = UUID(uuidString: deviceId),
      let peripheral = peripherals[uuid]
    else { return }
    centralManager.connect(peripheral, options: nil)
  }

  // Update Stats for a Device

  private func updateStats(
    for peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi: Int
  ) -> TrackerStats {

    let now = Date()
    let uuid = peripheral.identifier
    let isConnectable =
      (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false

    if var stats = trackerStats[uuid] {
      stats.lastSeen = now
      stats.rssiSamples.append(rssi)
      if stats.rssiSamples.count > 50 {
        stats.rssiSamples.removeFirst()  // prevent unbounded growth
      }
      stats.isConnectable = stats.isConnectable || isConnectable
      trackerStats[uuid] = stats
      return stats
    } else {
      let stats = TrackerStats(
        firstSeen: now,
        lastSeen: now,
        rssiSamples: [rssi],
        isConnectable: isConnectable
      )
      trackerStats[uuid] = stats
      return stats
    }
  }

  // Indirect AirTag / Tracker Suspicion Score (0.0 – 1.0)

  private func computeSuspicionScore(stats: TrackerStats, name: String?) -> Double {
    var score: Double = 0.0

    // 1) Unknown / empty name → more suspicious
    if name == nil || name == "Unknown" || name?.isEmpty == true {
      score += 0.3
    }

    // 2) Non-connectable beacon → like AirTag / Find My accessory
    if stats.isConnectable == false {
      score += 0.3
    }

    // 3) Seen for a while (persistent nearby presence)
    let duration = stats.lastSeen.timeIntervalSince(stats.firstSeen)
    if duration > 5 * 60 {  // > 5 minutes
      score += 0.2
    }
    if duration > 10 * 60 {  // > 10 minutes
      score += 0.1
    }

    // 4) RSSI stability (device "following" you, not jumping around)
    let values = stats.rssiSamples
    if values.count >= 3 {
      let mean = Double(values.reduce(0, +)) / Double(values.count)
      let variance =
        values.map { pow(Double($0) - mean, 2.0) }
        .reduce(0.0, +) / Double(values.count)
      let stdDev = sqrt(variance)

      // Typical "following distance" range and stability
      if mean > -80 && mean < -30 && stdDev < 10 {
        score += 0.2
      }
    }

    // Clamp to [0,1]
    return min(1.0, max(0.0, score))
  }

  // MARK: - CBCentralManagerDelegate

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .poweredOn:
      print("Bluetooth is ON")
    // Do NOT auto-start scanning — only when StartScan is pressed
    case .poweredOff:
      print("Bluetooth is OFF")
      centralManager.stopScan()
    case .resetting:
      print("Bluetooth resetting")
    case .unauthorized:
      print("Bluetooth unauthorized")
    case .unsupported:
      print("Bluetooth unsupported")
    case .unknown:
      print("Bluetooth state unknown")
    @unknown default:
      print("Bluetooth state unknown (future case)")
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    let rssiValue = RSSI.intValue
    if rssiValue == 127 { return }  // invalid RSSI

    peripherals[peripheral.identifier] = peripheral
    let name = peripheral.name ?? "Unknown"

    let stats = updateStats(
      for: peripheral,
      advertisementData: advertisementData,
      rssi: rssiValue
    )

    let suspicionScore = computeSuspicionScore(stats: stats, name: peripheral.name)
    let probability = Int(suspicionScore * 100.0)
    let isSuspicious = suspicionScore >= 0.6

    let seenDuration = Int(stats.lastSeen.timeIntervalSince(stats.firstSeen))

    let device: [String: Any] = [
      "type": "device",
      "name": name,
      "id": peripheral.identifier.uuidString,
      "rssi": rssiValue,
      "airTagScore": suspicionScore,
      "probability": probability,
      "isSuspicious": isSuspicious,
      "isConnectable": stats.isConnectable,
      "seenSeconds": seenDuration,
      "sampleCount": stats.rssiSamples.count,
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
  }

  // FlutterStreamHandler

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
