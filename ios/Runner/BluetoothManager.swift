// ---------------------------
// leofindit/ios/Runner/BluetoothManager.swift
// ---------------------------
import CoreBluetooth
import Flutter
import Foundation

// Manage Bluetooth scanning and device classification on iOS using CoreBluetooth
final class BluetoothManager: NSObject, CBCentralManagerDelegate {
  private let TX_POWER_TILE: Double = -59.0
  private let TX_POWER_APPLE: Double = -61.0
  private let TX_POWER_SAMSUNG: Double = -60.0
  private let TX_POWER_UNDESIGNATED: Double = -62.0
  private let PATH_LOSS_N: Double = 2.2
  private let TRACKER_TTL_MS: Int64 = 30_000
  private let channel: FlutterMethodChannel
  private var central: CBCentralManager!
  private var scanning = false
  private var pendingStart = false
  private var lastStartRequestMs: Int64 = 0
  private let START_REQUEST_TTL_MS: Int64 = 10_000

  private struct TrackerState {
    var lastSeenMs: Int64
    var firstSeenMs: Int64
    var sightings: Int
    var rotatingMacCount: Int
    var rawFrame: String
    var kind: String
    var lastRssi: Int
    var smoothedRssi: Int
    var lastSentMs: Int64 // <--- Throttling property
  }
  private var states: [String: TrackerState] = [:]

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
    self.central = CBCentralManager(delegate: self, queue: nil)
  }

  func bluetoothStateString() -> String {
    switch central.state {
    case .unknown: return "unknown"
    case .resetting: return "resetting"
    case .unsupported: return "unsupported"
    case .unauthorized: return "unauthorized"
    case .poweredOff: return "poweredOff"
    case .poweredOn: return "poweredOn"
    @unknown default: return "unknown"
    }
  }

  @discardableResult
  func startScan() -> Bool {
    let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
    if scanning { return true }
    guard central.state == .poweredOn else {
      pendingStart = true
      lastStartRequestMs = nowMs
      return false
    }
    pendingStart = false
    scanning = true
    central.scanForPeripherals(
      withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    return true
  }

  func stopScan() {
    pendingStart = false
    if !scanning { return }
    scanning = false
    central.stopScan()
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state != .poweredOn {
      stopScan()
      return
    }
    if pendingStart {
      let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
      if nowMs - lastStartRequestMs <= START_REQUEST_TTL_MS {
        pendingStart = false
        startScan()
      } else {
        pendingStart = false
      }
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    let rssi = RSSI.intValue
    if rssi == 127 { return }

    let kind = classifyKind(advertisementData: advertisementData)
    let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
    
    let rawFrame = extractManufacturerHex(advertisementData: advertisementData)
    let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? Bool) ?? false
    let localName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
    let serviceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
    let serviceUuidStrings = serviceUUIDs.map { $0.uuidString.uppercased() }

    let signature = peripheral.identifier.uuidString
    let prev = states[signature]
    let firstSeen = prev?.firstSeenMs ?? nowMs
    let sightings = (prev?.sightings ?? 0) + 1

    let priorSmooth = prev?.smoothedRssi ?? rssi
    let smoothed = Int((Double(priorSmooth) * 0.85) + (Double(rssi) * 0.15))
    let distanceFeet = estimateDistanceFeet(kind: kind, rssi: smoothed)

    var lastSent = prev?.lastSentMs ?? 0

    // Throttle updates to once every 300ms to increase responsiveness while preventing UI spam
    let shouldSendUpdate = (nowMs - lastSent) > 300

    if shouldSendUpdate {
      lastSent = nowMs
      
      let payload: [String: Any] = [
        "id": signature,
        "logicalId": signature,
        "address": NSNull(),
        "mac": "",
        "kind": kind,
        "rssi": rssi,
        "smoothedRssi": smoothed,
        "distanceFeet": distanceFeet,
        "firstSeenMs": Int(firstSeen),
        "lastSeenMs": Int(nowMs),
        "sightings": sightings,
        "signature": signature,
        "rawFrame": rawFrame,
        "rotatingMacCount": 0,
        "localName": localName,
        "isConnectable": isConnectable,
        "serviceUuids": serviceUuidStrings,
        "uuid": peripheral.identifier.uuidString,
      ]

      channel.invokeMethod("onDevice", arguments: payload)
    }

    states[signature] = TrackerState(
      lastSeenMs: nowMs,
      firstSeenMs: firstSeen,
      sightings: sightings,
      rotatingMacCount: 0,
      rawFrame: rawFrame,
      kind: kind,
      lastRssi: rssi,
      smoothedRssi: smoothed,
      lastSentMs: lastSent
    )
      
    // Periodic garbage collection to clear memory
    if sightings % 20 == 0 {
       states = states.filter { nowMs - $0.value.lastSeenMs <= TRACKER_TTL_MS }
    }
  }

  private func estimateDistanceFeet(kind: String, rssi: Int) -> Double {
    let txPower: Double
    switch kind {
    case "TILE": txPower = TX_POWER_TILE
    case "AIRTAG", "APPLE_DEVICE": txPower = TX_POWER_APPLE
    case "SAMSUNG_DEVICE", "SAMSUNG_SMARTTAG": txPower = TX_POWER_SAMSUNG
    default: txPower = TX_POWER_UNDESIGNATED
    }
    let ratio = (txPower - Double(rssi)) / (10.0 * PATH_LOSS_N)
    let meters = pow(10.0, ratio)
    let feet = meters * 3.28084
    return max(0.5, feet)
  }

  private func classifyKind(advertisementData: [String: Any]) -> String {
    let localName =
      (advertisementData[CBAdvertisementDataLocalNameKey] as? String)?.lowercased() ?? ""
    let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? Bool) ?? false
    let uuids = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
    let serviceStrings = uuids.map { $0.uuidString.uppercased() }
    let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data

    if localName.contains("tile") { return "TILE" }

    if localName.contains("smart tag") || localName.contains("smarttag")
      || localName.contains("galaxy smarttag")
    {
      return "SAMSUNG_SMARTTAG"
    }

    if let mfg = manufacturerData, let cid = companyId(from: mfg) {
      let rawUpper = mfg.map { String(format: "%02X", $0) }.joined()

      if cid == 0x0131 { return "TILE" }
      if cid == 0x0075 { return "SAMSUNG_SMARTTAG" }

      if cid == 0x004C {  // Apple
        if rawUpper.hasPrefix("4C001210") || rawUpper.hasPrefix("4C001219")
          || rawUpper.hasPrefix("4C000215") || rawUpper.hasPrefix("004C1210")
          || rawUpper.hasPrefix("004C1219") || rawUpper.hasPrefix("4C001220")
          || rawUpper.hasPrefix("4C001221") || rawUpper.hasPrefix("4C001222")
        {
          return "AIRTAG"
        }
        return "APPLE_DEVICE"
      }
    }

    // 4. Service UUID checks
    if serviceStrings.contains(where: { $0.contains("FD44") }) { return "AIRTAG" }
    
    if serviceStrings.contains(where: {
      $0.contains("FEED") || $0.contains("FEEC") || $0.contains("FEE7")
    }) {
      return "TILE"
    }
    
    // Explicitly catch Samsung SmartThings find Service UUID
    if serviceStrings.contains(where: { $0.contains("FD5A") }) { 
      return "SAMSUNG_SMARTTAG" 
    }
    
    // Generic Samsung
    if serviceStrings.contains(where: {
      $0.contains("FD59") || $0.contains("FD5B") || $0.contains("FDE2")
    }) || localName.contains("samsung") {
      return "SAMSUNG_DEVICE"
    }

    if localName.isEmpty {
      if isConnectable {
        return "AIRTAG"  // Real stripped AirTags
      } else {
        return "APPLE_DEVICE"  // Most other Apple devices
      }
    }

    return "UNDESIGNATED"
  }

  private func companyId(from manufacturerData: Data) -> UInt16? {
    guard manufacturerData.count >= 2 else { return nil }
    let b0 = UInt16(manufacturerData[manufacturerData.startIndex])
    let b1 = UInt16(manufacturerData[manufacturerData.startIndex + 1])
    return b0 | (b1 << 8)
  }

  private func extractManufacturerHex(advertisementData: [String: Any]) -> String {
    guard let mfg = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
      return ""
    }
    return mfg.map { String(format: "%02X", $0) }.joined()
  }
}
