// lib/models.dart
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

  // Legacy getters used in older pages
  String get displayUuid {
    if (signature.length <= 8) return signature;
    return signature.substring(signature.length - 8);
  }

  String get shortUuid {
    if (signature.length <= 8) return signature;
    return signature.substring(signature.length - 8);
  }

  String get displayMac => shortUuid;

  // FINAL TIGHTENED LOGIC – only real close AirTags will trigger
  bool get isPossibleAirTag {
    if (isLikelyAirTag) return true;
    final n = localName.toLowerCase().trim();
    if (n.isNotEmpty) return false; // AirTags always empty name
    final isVeryClose = smoothedRssi >= -52;
    final hasEnoughSightings = sightings >= 5;
    return kind == 'APPLE_DEVICE' &&
        isConnectable &&
        isVeryClose &&
        hasEnoughSightings;
  }

  String get displayName {
    final customName = DeviceMarks.getName(signature);
    if (customName != null && customName.isNotEmpty) return customName;

    if (isLikelyAirTag || isPossibleAirTag) {
      return 'Apple AirTag';
    }

    if (kind == 'APPLE_DEVICE') {
      return 'Undesignated Device'; // ← changed as requested
    }

    if (isLikelyTile) return 'Life360 Tile';
    if (isLikelySamsung) return 'Samsung SmartTag';

    return 'Undesignated Tracker'; // everything else
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
      smoothedRssi: ((m['smoothedRssi'] as num?) ?? (m['rssi'] as num?) ?? -100)
          .toDouble(),
      localName: (m['localName'] as String?) ?? '',
      isConnectable: (m['isConnectable'] as bool?) ?? false,
      serviceUuids: ((m['serviceUuids'] as List?) ?? []).cast<String>(),
      rotatingMacCount: (m['rotatingMacCount'] as int?) ?? 0,
    );
  }
}

// Tracker icons
Widget buildTrackerImage(TrackerDevice d, {double size = 44}) {
  String assetName = 'assets/unknown.png';
  if (d.isLikelyAirTag || d.isPossibleAirTag) {
    assetName = 'assets/airtag.png';
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
