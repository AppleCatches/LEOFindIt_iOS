import 'package:flutter/material.dart';
import 'device_marks.dart';

// Model for representing detected tracker devices and their properties
class TrackerDevice {
  final String signature;
  final String id;
  final String kind;
  final int rssi;
  final double distanceFeet;
  final int firstSeenMs;
  final int lastSeenMs;
  final int sightings;
  final String rawFrame;
  final double smoothedRssi;
  final String localName;
  final bool isConnectable;
  final List<String> serviceUuids;
  final int rotatingMacCount;

  TrackerDevice({
    required this.signature,
    required this.id,
    required this.kind,
    required this.rssi,
    required this.distanceFeet,
    required this.firstSeenMs,
    required this.lastSeenMs,
    required this.sightings,
    required this.rawFrame,
    required this.smoothedRssi,
    required this.localName,
    required this.isConnectable,
    required this.serviceUuids,
    required this.rotatingMacCount,
  });

  TrackerDevice merge(TrackerDevice other) {
    return TrackerDevice(
      signature: signature,
      id: other.id,
      kind: other.kind,
      rssi: other.rssi,
      distanceFeet: other.distanceFeet,
      firstSeenMs: firstSeenMs,
      lastSeenMs: other.lastSeenMs,
      sightings: other.sightings,
      rawFrame: other.rawFrame,
      smoothedRssi: other.smoothedRssi,
      localName: other.localName,
      isConnectable: other.isConnectable,
      serviceUuids: other.serviceUuids,
      rotatingMacCount: other.rotatingMacCount,
    );
  }

  String get stableKey => signature;
  double get distanceUiM => distanceFeet / 3.28084;
  double get distanceFt => distanceFeet;

  bool get isLikelyFindMy => kind == 'FIND_MY' || kind == 'APPLE_DEVICE' || kind.contains('APPLE');
  bool get mayBeRotatingDuplicate => rotatingMacCount > 1 && (isLikelyAirTag || isLikelyFindMy);

  double get distance => distanceFeet;
  double get distanceMeters => distanceFeet / 3.28084;
  String get distanceFtLabel =>
      '${distanceFeet.toStringAsFixed(distanceFeet < 10 ? 1 : 0)} ft';

  bool get isLikelyAirTag => kind == 'AIRTAG';
  bool get isLikelyTile => kind == 'TILE';
  bool get isLikelySamsung =>
      kind == 'SAMSUNG' ||
      kind == 'SAMSUNG_DEVICE' ||
      kind == 'SAMSUNG_SMARTTAG';

  String get displayUuid {
    if (signature.length <= 8) return signature;
    return signature.substring(signature.length - 8);
  }

  String get shortUuid {
    if (signature.length <= 4) return signature;
    return signature.substring(signature.length - 4);
  }

  String get displayMac => shortUuid;

  bool get isPossibleAirTag {
    if (isLikelyAirTag) return true;
    final n = localName.toLowerCase().trim();
    if (n.isNotEmpty) return false;
    final isVeryClose = smoothedRssi >= -52;
    final hasEnoughSightings = sightings >= 5;
    return kind == 'APPLE_DEVICE' &&
        isConnectable &&
        isVeryClose &&
        hasEnoughSightings;
  }

  String get displayName {
    if (isLikelyAirTag || isPossibleAirTag) {
      return 'Apple AirTag';
    }
    if (isLikelyFindMy) {
      return 'AppleFindMy';
    }
    if (isLikelyTile) return 'Life360 Tile';
    if (isLikelySamsung) return 'Samsung SmartTag';

    return 'Undesignated Device'; 
  }

  factory TrackerDevice.fromNative(Map<String, dynamic> m) {
    return TrackerDevice(
      signature: (m['signature'] as String?) ?? '',
      id: (m['id'] as String?) ?? '',
      kind: (m['kind'] as String?) ?? 'UNDESIGNATED',
      rssi: (m['rssi'] as int?) ?? -100,
      distanceFeet: ((m['distanceFeet'] as num?) ?? 0).toDouble(),
      firstSeenMs: (m['firstSeenMs'] as int?) ?? (m['lastSeenMs'] as int?) ?? 0,
      lastSeenMs: (m['lastSeenMs'] as int?) ?? 0,
      sightings: (m['sightings'] as int?) ?? 1,
      rawFrame: (m['rawFrame'] as String?) ?? '',
      smoothedRssi: ((m['smoothedRssi'] as num?) ?? (m['rssi'] as num?) ?? -100).toDouble(),
      localName: (m['localName'] as String?) ?? '',
      isConnectable: (m['isConnectable'] as bool?) ?? false,
      serviceUuids: ((m['serviceUuids'] as List?) ?? []).cast<String>(),
      rotatingMacCount: (m['rotatingMacCount'] as int?) ?? 0,
    );
  }
}

Widget buildTrackerImage(TrackerDevice d, {double size = 44}) {
  String assetName = 'assets/unknown.png';
  if (d.isLikelyAirTag || d.isPossibleAirTag) {
    assetName = 'assets/airtag.png';
  } else if (d.isLikelyFindMy) {
    assetName = 'assets/applefindmy.png';
  } else if (d.isLikelyTile) {
    assetName = 'assets/tile.png';
  } else if (d.isLikelySamsung) {
    assetName = 'assets/smarttag.png';
  }
  return Image.asset(
    assetName,
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) {
      return Icon(
        Icons.bluetooth_searching,
        size: size,
        color: Colors.blueAccent,
      );
    },
  );
}

// android version
/*
enum DeviceStatus { undesignated, friendly, nonsuspect, suspect }

extension DeviceStatusX on DeviceStatus {
  String get label {
    switch (this) {
      case DeviceStatus.undesignated:
        return "Undesignated";
      case DeviceStatus.friendly:
        return "Friendly";
      case DeviceStatus.nonsuspect:
        return "Nonsuspect";
      case DeviceStatus.suspect:
        return "Suspect";
    }
  }
}

class TrackerDevice {
  final String signature;
  final String id;
  final String logicalId;
  final String kind;
  final String? pinnedMac;
  final String? lastMac;
  final int rssi;
  final double distanceMeters;
  final int firstSeenMs;
  final int lastSeenMs;
  final int sightings;
  final int rotatingMacCount;
  final String rawFrame;
  final double smoothedRssi;
  final double smoothedDistanceMeters;
  final DeviceStatus status;

  static const double _mToFt = 3.28084;

  TrackerDevice({
    required this.signature,
    required this.id,
    required this.logicalId,
    required this.kind,
    required this.pinnedMac,
    required this.lastMac,
    required this.rssi,
    required this.distanceMeters,
    required this.firstSeenMs,
    required this.lastSeenMs,
    required this.sightings,
    required this.rotatingMacCount,
    required this.rawFrame,
    required this.smoothedRssi,
    required this.smoothedDistanceMeters,
    required this.status,
  });

  String get stableKey {
    if (logicalId.isNotEmpty) return logicalId;
    if (id.isNotEmpty) return id;
    return signature;
  }

  double get distanceM => distanceMeters;
  double get distanceUiM => smoothedDistanceMeters;
  double get distanceFt => distanceUiM * _mToFt;

  String get distanceFtLabel =>
      '${distanceFt.toStringAsFixed(distanceFt < 10 ? 1 : 0)} ft';

  double get distance => distanceMeters;


  bool get isLikelyAirTag => kind == 'AIRTAG';
  bool get isLikelyFindMy => kind == 'FIND_MY';
  bool get isLikelyTile => kind == 'TILE';
  bool get isLikelySamsung => kind == 'SAMSUNG';


  String get displayName {
    if (isLikelyAirTag) return 'Apple AirTag';
    if (isLikelyFindMy) return 'Apple Find My'; // ← Ridge wallet shows this
    if (isLikelyTile) return 'Life360 Tile';
    if (isLikelySamsung) return 'Samsung SmartTag';

    if (kind.contains('APPLE')) return 'Apple Device';
    return 'Unknown Tracker';
  }

  String get displayMac => pinnedMac ?? lastMac ?? 'Unavailable';

  String get displayUuid {
    if (logicalId.isNotEmpty) return logicalId;
    if (id.isNotEmpty) return id;
    if (signature.isNotEmpty) return signature;
    return 'Unavailable';
  }

  String get shortMac {
    final mac = displayMac;
    if (mac == 'Unavailable') return mac;
    if (mac.length <= 8) return mac;
    return mac.substring(mac.length - 8);
  }

  String get macTail4 {
    final mac = displayMac.replaceAll(':', '').replaceAll('-', '');
    if (mac.isEmpty || mac == 'Unavailable') return '----';
    if (mac.length <= 4) return mac.toUpperCase();
    return mac.substring(mac.length - 4).toUpperCase();
  }

  bool get mayBeRotatingDuplicate =>
      rotatingMacCount > 1 && (isLikelyAirTag || isLikelyFindMy);
  String get shortUuid {
    final uuid = displayUuid;
    if (uuid == 'Unavailable') return uuid;
    if (uuid.length <= 8) return uuid;
    return uuid.substring(uuid.length - 8);
  }

  TrackerDevice withStatus(DeviceStatus s) => TrackerDevice(
    signature: signature,
    id: id,
    logicalId: logicalId,
    kind: kind,
    pinnedMac: pinnedMac,
    lastMac: lastMac,
    rssi: rssi,
    distanceMeters: distanceMeters,
    firstSeenMs: firstSeenMs,
    lastSeenMs: lastSeenMs,
    sightings: sightings,
    rotatingMacCount: rotatingMacCount,
    rawFrame: rawFrame,
    smoothedRssi: smoothedRssi,
    smoothedDistanceMeters: smoothedDistanceMeters,
    status: s,
  );

  TrackerDevice merge(TrackerDevice newer) {
    final preservedStatus = status;

    final double prevRssi = smoothedRssi;
    final double rawRssi = newer.rssi.toDouble();

    const double rssiAlpha = 0.18;
    final smoothedRssiNew = (prevRssi * (1 - rssiAlpha)) + (rawRssi * rssiAlpha);

    final prevD = smoothedDistanceMeters;
    final rawD = newer.distanceMeters;

    final int dtMs = (newer.lastSeenMs - lastSeenMs).clamp(1, 60000);
    final double dtS = dtMs / 1000.0;

    const double maxSpeedMps = 2.2;
    final double maxDelta = maxSpeedMps * dtS;

    double clampedRaw = rawD;
    if (prevD > 0 && rawD > 0) {
      final double delta = rawD - prevD;
      if (delta.abs() > maxDelta) {
        clampedRaw =
            prevD + (delta.isNegative ? -maxDelta : maxDelta);
      }
    }

    const double distAlpha = 0.08;
    final double smoothedDistNew =
        (prevD * (1 - distAlpha)) + (clampedRaw * distAlpha);

    return TrackerDevice(
      signature: newer.signature.isNotEmpty ? newer.signature : signature,
      id: newer.id.isNotEmpty ? newer.id : id,
      logicalId: newer.logicalId.isNotEmpty ? newer.logicalId : logicalId,
      kind: newer.kind.isNotEmpty ? newer.kind : kind,
      pinnedMac: pinnedMac ?? newer.lastMac,
      lastMac: newer.lastMac,
      rssi: newer.rssi,
      distanceMeters: newer.distanceMeters,
      firstSeenMs: firstSeenMs,
      lastSeenMs: newer.lastSeenMs,
      sightings: sightings + 1,
      rotatingMacCount: newer.rotatingMacCount,
      rawFrame: newer.rawFrame,
      smoothedRssi: smoothedRssiNew,
      smoothedDistanceMeters: smoothedDistNew,
      status: preservedStatus,
    );
  }

  factory TrackerDevice.fromNative(Map<String, dynamic> m) {
    final mac = m['address'] as String?;
    final int rssi = (m['rssi'] as int?) ?? -100;
    final double dist = ((m['distanceMeters'] as num?) ?? 0).toDouble();
    final int lastSeen =
        (m['lastSeenMs'] as int?) ?? DateTime.now().millisecondsSinceEpoch;

    return TrackerDevice(
      signature: (m['signature'] as String?) ?? '',
      id: (m['id'] as String?) ?? '',
      logicalId: (m['logicalId'] as String?) ?? '',
      kind: (m['kind'] as String?) ?? 'UNKNOWN',
      pinnedMac: null,
      lastMac: mac,
      rssi: rssi,
      distanceMeters: dist,
      firstSeenMs: (m['firstSeenMs'] as int?) ?? lastSeen,
      lastSeenMs: lastSeen,
      sightings: (m['sightings'] as int?) ?? 1,
      rotatingMacCount: (m['rotatingMacCount'] as int?) ?? 1,
      rawFrame: (m['rawFrame'] as String?) ?? '',
      smoothedRssi: ((m['smoothedRssi'] as num?) ?? rssi).toDouble(),
      smoothedDistanceMeters:
      ((m['smoothedDistanceMeters'] as num?) ?? dist).toDouble(),
      status: DeviceStatus.undesignated,
    );
  }
}
*/