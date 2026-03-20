// ---------------------------
// leofindit_ios/ios/Runner/BluetoothManager.swift
// ---------------------------

import CoreBluetooth
import Flutter
import Foundation

// Manage Bluetooth scanning and device classification on iOS using CoreBluetooth
final class BluetoothManager: NSObject, CBCentralManagerDelegate {
  // RSSI values at 1 meter for different device types, used for distance estimation
  private let TX_POWER_TILE: Double = -59.0
  private let TX_POWER_APPLE: Double = -61.0
  private let TX_POWER_SAMSUNG: Double = -60.0
  private let TX_POWER_UNKNOWN: Double = -62.0

  private let PATH_LOSS_N: Double = 2.2
  private let TRACKER_TTL_MS: Int64 = 30_000

  private let channel: FlutterMethodChannel
  private var central: CBCentralManager!

  private var scanning = false
  private var pendingStart = false
  private var lastStartRequestMs: Int64 = 0
  private let START_REQUEST_TTL_MS: Int64 = 10_000

  // State of a detected btle device including timing, signal strength, and classification
  private struct TrackerState {
    var lastSeenMs: Int64
    var firstSeenMs: Int64
    var sightings: Int
    var rotatingMacCount: Int
    var rawFrame: String
    var kind: String
    var lastRssi: Int
    var smoothedRssi: Int
  }

  private var states: [String: TrackerState] = [:]

  // Initialize BluetoothManager with a Flutter method channel and set up the CBCentralManager for Bluetooth scanning
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

  // Start Bluetooth scanning if the central manager is powered on, otherwise sets a pending start flag to attempt scanning when the state updates
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

    // Scan for all peripherals, allowing duplicates to receive continuous updates from devices
    central.scanForPeripherals(
      withServices: nil,
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
    )
    return true
  }

  // Stop Bluetooth scanning if it is currently active, and reset the scanning state
  func stopScan() {
    pendingStart = false
    if !scanning { return }
    scanning = false
    central.stopScan()
  }

  // CBCentralManagerDelegate method called when the Bluetooth state updates.
  // Checks if Bluetooth is powered on and either starts scanning or stops it based on the new state and any pending start requests
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state != .poweredOn {
      stopScan()
      return
    }

    // If pending start request and Bluetooth is powered on, check if the request is still valid based on the time it was made
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

  // CBCentralManagerDelegate method called when a peripheral is discovered during scanning
  // Process the advertisement data, classify the device, update its state, and send relevant info back to the Flutter layer
  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    let rssi = RSSI.intValue
    if rssi == 127 { return }

    let nowMs = Int64(Date().timeIntervalSince1970 * 1000)

    states = states.filter { nowMs - $0.value.lastSeenMs <= TRACKER_TTL_MS }

    // Extract relevant info used for device classification and reporting
    let rawFrame = extractManufacturerHex(advertisementData: advertisementData)
    let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? Bool) ?? false
    let localName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
    let serviceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
    let serviceUuidStrings = serviceUUIDs.map { $0.uuidString.uppercased() }

    let kind = classifyKind(advertisementData: advertisementData)

    // UUID-based identity on iOS
    let signature = "IOS_\(peripheral.identifier.uuidString)"

    // Update the state for the detected device
    let prev = states[signature]
    let firstSeen = prev?.firstSeenMs ?? nowMs
    let sightings = (prev?.sightings ?? 0) + 1

    // Apply a simple smoothing algorithm to the RSSI values to reduce fluctuations and provide a more stable estimate of the signal strength
    let priorSmooth = prev?.smoothedRssi ?? rssi
    let smoothed = Int((Double(priorSmooth) * 0.4) + (Double(rssi) * 0.6))
    let distanceMeters = estimateDistanceMeters(kind: kind, rssi: smoothed)

    // Update the state dictionary with the new information for the detected device
    states[signature] = TrackerState(
      lastSeenMs: nowMs,
      firstSeenMs: firstSeen,
      sightings: sightings,
      rotatingMacCount: 0,
      rawFrame: rawFrame,
      kind: kind,
      lastRssi: rssi,
      smoothedRssi: smoothed
    )

    // Prepare the payload to be sent to the Flutter layer
    let payload: [String: Any] = [
      "id": "\(kind)_\(signature)",
      "logicalId": "\(kind)_\(signature)",
      "address": NSNull(),
      "mac": "",
      "kind": kind,
      "rssi": rssi,
      "smoothedRssi": smoothed,
      "distanceMeters": distanceMeters,
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

    print(
      "BLE kind=\(kind) name=\(localName) rssi=\(rssi) smooth=\(smoothed) conn=\(isConnectable) services=\(serviceUuidStrings) mfg=\(rawFrame)"
    )
    channel.invokeMethod("onDevice", arguments: payload)
  }

  // Estimate the distance to a Bluetooth device based on its RSSI value and classification
  private func estimateDistanceMeters(kind: String, rssi: Int) -> Double {
    let txPower: Double
    switch kind {
    case "TILE":
      txPower = TX_POWER_TILE
    case "AIRTAG", "APPLE_DEVICE":
      txPower = TX_POWER_APPLE
    case "SAMSUNG_DEVICE", "SAMSUNG_SMARTTAG":
      txPower = TX_POWER_SAMSUNG
    default:
      txPower = TX_POWER_UNKNOWN
    }

    // Distance estimation: distance = 10 ^ ((txPower - rssi) / (10 * n))
    // Provides an estimate of the distance in meters
    let ratio = (txPower - Double(rssi)) / (10.0 * PATH_LOSS_N)
    let meters = pow(10.0, ratio)
    return max(0.05, meters)
  }

  // Classify the type of Bluetooth device based on its advertisement data
  private func classifyKind(advertisementData: [String: Any]) -> String {
    let localName =
      (advertisementData[CBAdvertisementDataLocalNameKey] as? String)?.lowercased() ?? ""

    let isConnectable =
      (advertisementData[CBAdvertisementDataIsConnectable] as? Bool) ?? false

    let uuids =
      (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
    let serviceStrings = uuids.map { $0.uuidString.uppercased() }

    // Local-name checks first
    if localName.contains("tile") {
      return "TILE"
    }

    if localName.contains("smart tag") || localName.contains("smarttag") {
      return "SAMSUNG_SMARTTAG"
    }

    if localName.contains("galaxy smarttag") {
      return "SAMSUNG_SMARTTAG"
    }

    // Manufacturer-data checks
    if let mfg = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
      mfg.count >= 2
    {

      let rawUpper = mfg.map { String(format: "%02X", $0) }.joined()

      let b0 = UInt16(mfg[mfg.startIndex])
      let b1 = UInt16(mfg[mfg.startIndex + 1])
      let companyId = b0 | (b1 << 8)

      // Tile
      if companyId == 0x0131 {
        return "TILE"
      }

      // Samsung
      if companyId == 0x0075 {
        if localName.contains("smart") || localName.contains("tag") {
          return "SAMSUNG_SMARTTAG"
        }
        return "SAMSUNG_DEVICE"
      }

      // Apple
      if companyId == 0x004C {
        // Keep both known patterns enabled
        if rawUpper.hasPrefix("1EFF4C001219") || rawUpper.hasPrefix("1EFF4C000215")
          || rawUpper.hasPrefix("1AFF4C000215")
        {
          return "AIRTAG"
        }

        // If Apple manufacturer data exists with no friendly name and not connectable,
        // treat it as a likely Find My / AirTag-family broadcast
        if localName.isEmpty && !isConnectable {
          return "APPLE_DEVICE"
        }

        return "APPLE_DEVICE"
      }
    }

    // Service UUID checks
    if serviceStrings.contains(where: { $0.contains("FD44") }) {
      return "AIRTAG"
    }

    if serviceStrings.contains(where: { $0.contains("FEED") || $0.contains("FEE7") }) {
      return "TILE"
    }

    // Samsung fallback heuristics
    if localName.contains("samsung") {
      if localName.contains("tag") || localName.contains("smart") {
        return "SAMSUNG_SMARTTAG"
      }
      return "SAMSUNG_DEVICE"
    }

    if serviceStrings.contains(where: {
      $0.contains("FD5A") || $0.contains("FD5B") || $0.contains("FDE2")
    }) {
      return "SAMSUNG_DEVICE"
    }

    // Apple fallback
    if localName.isEmpty && !isConnectable && !serviceStrings.isEmpty {
      return "APPLE_DEVICE"
    }

    return "UNKNOWN"
  }

  // Extract the manufacturer data from the advertisement data and convert it to a hexadecimal string representation
  private func extractManufacturerHex(advertisementData: [String: Any]) -> String {
    guard let mfg = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
      return ""
    }
    return mfg.map { String(format: "%02x", $0) }.joined()
  }
}
