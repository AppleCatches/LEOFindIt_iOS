// Model for representing detected tracker devices and their properties
import 'device_marks.dart';

class TrackerDevice {
  final String signature;
  final String id;
  final String kind;

  final String? pinnedMac;
  final String? lastMac;

  final int rssi;
  final double distanceFeet;
  final int firstSeenMs;
  final int lastSeenMs;
  final int sightings;
  final int rotatingMacCount;
  final String rawFrame;

  final double smoothedRssi;

  final String localName;
  final bool isConnectable;
  final List<String> serviceUuids;

  //Conversion factor from meters to feet for distance calculations
  // static const double _mToFt = 3.28084;

  // Constructor for creating a TrackerDevice instance with all properties
  TrackerDevice({
    required this.signature,
    required this.id,
    required this.kind,
    required this.pinnedMac,
    required this.lastMac,
    required this.rssi,
    required this.distanceFeet,
    required this.firstSeenMs,
    required this.lastSeenMs,
    required this.sightings,
    required this.rotatingMacCount,
    required this.rawFrame,
    required this.smoothedRssi,
    required this.localName,
    required this.isConnectable,
    required this.serviceUuids,
  });

  /*
  double get distanceM => distanceMeters;
  double get distanceFt => distanceMeters * _mToFt;

  String get distanceFtLabel =>
      '${distanceFt.toStringAsFixed(distanceFt < 10 ? 1 : 0)} ft';

  double get distance => distanceMeters;
  */

  double get distance => distanceFeet;
  String get distanceFtLabel =>
      '${distanceFeet.toStringAsFixed(distanceFeet < 10 ? 1 : 0)} ft';

  // Convenience getters to determine if the device is likely an AirTag, Tile, or Samsung SmartTag
  bool get isLikelyAirTag => kind == 'AIRTAG';
  bool get isLikelyTile => kind == 'TILE';

  bool get isLikelySamsung =>
      kind == 'SAMSUNG' ||
      kind == 'SAMSUNG_DEVICE' ||
      kind == 'SAMSUNG_SMARTTAG';

  bool get isPossibleAirTag {
    final n = localName.toLowerCase().trim();
    if (isLikelyAirTag) return true;
    final looksUnnamed = n.isEmpty || n == 'unknown';

    final notObviousAppleHost =
        !n.contains('iphone') &&
        !n.contains('ipad') &&
        !n.contains('macbook') &&
        !n.contains('airpods') &&
        !n.contains('watch') &&
        !n.contains('imac') &&
        !n.contains('apple tv');

    final hasTrackerLikePresence = sightings >= 2;
    final signalIsRelevant = smoothedRssi >= -85;

    final hasAppleLikeSignature =
        kind == 'APPLE_DEVICE' ||
        rawFrame.toLowerCase().contains('4c00') ||
        serviceUuids.isNotEmpty;

    return (kind == 'APPLE_DEVICE' || kind == 'UNKNOWN') &&
        looksUnnamed &&
        !isConnectable &&
        hasTrackerLikePresence &&
        signalIsRelevant &&
        hasAppleLikeSignature &&
        notObviousAppleHost;
  }

  // A device is considered "found" if it's estimated to be within 10 centimeters, which is a common threshold for determining if a tracker is very close.
  bool get isFound => distanceFeet <= 0.10;

  // Determine if a detected device is not a tracker
  // Filter out common devices that may be detected but are not the target trackers
  bool get looksLikeNonTracker {
    final n = localName.toLowerCase();

    if (isPossibleAirTag) {
      return false;
    }

    // Check for common device names that are unlikely to be trackers
    if (n.contains('macbook') ||
        n.contains('iphone') ||
        n.contains('ipad') ||
        n.contains('watch') ||
        n.contains('airpods') ||
        n.contains('imac') ||
        n.contains('apple tv')) {
      return true;
    }

    // If the device is connectable but does not have the characteristics of known trackers, it's likely not a tracker
    if (isConnectable &&
        !isLikelyTile &&
        !isLikelySamsung &&
        !isLikelyAirTag &&
        !isPossibleAirTag) {
      return true;
    }
    return false;
  }

  // A user-friendly display name for the device, based on its kind and characteristics
  String get displayName {
    final customName = DeviceMarks.getName(signature);
    if (customName != null && customName.isNotEmpty) return customName;
    
    if (isLikelyAirTag) return 'Apple AirTag';
    if (isPossibleAirTag) return 'Possible Apple AirTag';
    if (isLikelyTile) return 'Tile Tracker';

    if (kind == 'SAMSUNG_SMARTTAG' || kind == 'SAMSUNG') {
      return 'Samsung SmartTag';
    }
    if (kind == 'SAMSUNG_DEVICE') return 'Samsung BLE Device';

    if (kind.contains('APPLE')) return 'Apple Find My Device';
    return 'Unknown Tracker';
  }

  // Helps users identify the device based on its MAC address when possible
  String get displayUuid {
    if (signature.startsWith('IOS_')) {
      return signature.replaceFirst('IOS_', '');
    }
    return signature;
  }

  // Merge the current TrackerDevice instance with a newer detection to allow the smoothing of values over time and maintaining a consistent representation of the device as it is detected multiple times
  TrackerDevice merge(TrackerDevice newer) {
    final smoothed = (smoothedRssi * 0.4) + (newer.rssi * 0.6);

    // When merging, keep the original signature, id, kind, and first seen time, but update properties that may change with each detection
    return TrackerDevice(
      signature: signature,
      id: id,
      kind: newer.kind.isNotEmpty ? newer.kind : kind,
      pinnedMac: pinnedMac ?? newer.pinnedMac,
      lastMac: newer.lastMac,
      rssi: newer.rssi,
      distanceFeet: newer.distanceFeet,
      firstSeenMs: firstSeenMs,
      lastSeenMs: newer.lastSeenMs,
      sightings: sightings + 1,
      rotatingMacCount: newer.rotatingMacCount,
      rawFrame: newer.rawFrame,
      smoothedRssi: smoothed,
      localName: newer.localName,
      isConnectable: newer.isConnectable,
      serviceUuids: newer.serviceUuids,
    );
  }

  // Easy conversion of the raw data provided by the native code into a structured TrackerDevice instance that can be used within the Flutter app
  factory TrackerDevice.fromNative(Map<String, dynamic> m) {
    final mac = m['address'] as String?;
    final rotating = (m['rotatingMacCount'] as int?) ?? 0;
    final shouldPin = mac != null && rotating <= 1;

    // Apply the same logic for determining the pinned MAC address as we do in the merge function, ensuring consistency in how to handle MAC addresses across detections
    return TrackerDevice(
      signature: (m['signature'] as String?) ?? '',
      id: (m['id'] as String?) ?? '',
      kind: (m['kind'] as String?) ?? 'UNKNOWN',
      pinnedMac: shouldPin ? mac : null,
      lastMac: mac,
      rssi: (m['rssi'] as int?) ?? -100,
      distanceFeet: ((m['distanceFeet'] as num?) ?? 0).toDouble(),
      firstSeenMs: (m['firstSeenMs'] as int?) ?? (m['lastSeenMs'] as int?) ?? 0,
      lastSeenMs: (m['lastSeenMs'] as int?) ?? 0,
      sightings: (m['sightings'] as int?) ?? 1,
      rotatingMacCount: rotating,
      rawFrame: (m['rawFrame'] as String?) ?? '',
      smoothedRssi: ((m['smoothedRssi'] as num?) ?? (m['rssi'] as num?) ?? -100)
          .toDouble(),
      localName: (m['localName'] as String?) ?? '',
      isConnectable: (m['isConnectable'] as bool?) ?? false,
      serviceUuids: ((m['serviceUuids'] as List?) ?? []).cast<String>(),
    );
  }
}
