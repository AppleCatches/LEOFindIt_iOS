import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'device_marks.dart';

class TrackerReport {
  final String reportId;
  final DateTime createdAt;

  final String signature;
  final String id;
  final String kind;
  final String mac;

  final int rssi;
  final double distanceMeters;
  final int firstSeenMs;
  final int lastSeenMs;
  final int rotatingMacCount;

  final String rawFrame;

  // Where the exported file was saved (content:// uri on Android)
  final String? exportedUriJson;
  final String? exportedUriTxt;

  // Optional user feedback
  final String? teamFeedback;

  TrackerReport({
    required this.reportId,
    required this.createdAt,
    required this.signature,
    required this.id,
    required this.kind,
    required this.mac,
    required this.rssi,
    required this.distanceMeters,
    required this.firstSeenMs,
    required this.lastSeenMs,
    required this.rotatingMacCount,
    required this.rawFrame,
    this.exportedUriJson,
    this.exportedUriTxt,
    this.teamFeedback,
  });

  TrackerReport copyWith({
    String? exportedUriJson,
    String? exportedUriTxt,
    String? teamFeedback,
  }) {
    return TrackerReport(
      reportId: reportId,
      createdAt: createdAt,
      signature: signature,
      id: id,
      kind: kind,
      mac: mac,
      rssi: rssi,
      distanceMeters: distanceMeters,
      firstSeenMs: firstSeenMs,
      lastSeenMs: lastSeenMs,
      rotatingMacCount: rotatingMacCount,
      rawFrame: rawFrame,
      exportedUriJson: exportedUriJson ?? this.exportedUriJson,
      exportedUriTxt: exportedUriTxt ?? this.exportedUriTxt,
      teamFeedback: teamFeedback ?? this.teamFeedback,
    );
  }

  Map<String, dynamic> toJson() => {
    "reportId": reportId,
    "createdAt": createdAt.toIso8601String(),
    "signature": signature,
    "id": id,
    "kind": kind,
    "mac": mac,
    "rssi": rssi,
    "distanceMeters": distanceMeters,
    "firstSeenMs": firstSeenMs,
    "lastSeenMs": lastSeenMs,
    "rotatingMacCount": rotatingMacCount,
    "rawFrame": rawFrame,
    "exportedUriJson": exportedUriJson,
    "exportedUriTxt": exportedUriTxt,
    "teamFeedback": teamFeedback,
  };

  static TrackerReport fromJson(Map<String, dynamic> j) => TrackerReport(
    reportId: (j["reportId"] as String?) ?? "",
    createdAt: DateTime.tryParse((j["createdAt"] as String?) ?? "") ??
        DateTime.fromMillisecondsSinceEpoch(0),
    signature: (j["signature"] as String?) ?? "",
    id: (j["id"] as String?) ?? "",
    kind: (j["kind"] as String?) ?? "",
    mac: (j["mac"] as String?) ?? "",
    rssi: (j["rssi"] as int?) ?? -100,
    distanceMeters: (j["distanceMeters"] as num?)?.toDouble() ?? 0.0,
    firstSeenMs: (j["firstSeenMs"] as int?) ?? 0,
    lastSeenMs: (j["lastSeenMs"] as int?) ?? 0,
    rotatingMacCount: (j["rotatingMacCount"] as int?) ?? 0,
    rawFrame: (j["rawFrame"] as String?) ?? "",
    exportedUriJson: j["exportedUriJson"] as String?,
    exportedUriTxt: j["exportedUriTxt"] as String?,
    teamFeedback: j["teamFeedback"] as String?,
  );
}

class ReportsStore {
  static const MethodChannel _storage = MethodChannel("leo_find_it/storage");

  static final ValueNotifier<List<TrackerReport>> notifier =
  ValueNotifier<List<TrackerReport>>([]);

  static Future<void> init() async {
    try {
      final f = await _reportsFile();
      if (!await f.exists()) return;

      final txt = await f.readAsString();
      if (txt.trim().isEmpty) return;

      final decoded = jsonDecode(txt);
      if (decoded is! List) return;

      final list = decoded
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .map(TrackerReport.fromJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      notifier.value = list;
    } catch (_) {
      // don't crash
    }
  }

  static Future<void> _persist() async {
    final f = await _reportsFile();
    final list = notifier.value.map((r) => r.toJson()).toList();
    await f.writeAsString(jsonEncode(list));
  }

  static Future<File> _reportsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/leo_reports.json");
  }

  static String _newId() => DateTime.now().millisecondsSinceEpoch.toString();

  static Future<TrackerReport> createFromDevice(TrackerDevice d) async {
    final report = TrackerReport(
      reportId: _newId(),
      createdAt: DateTime.now(),
      signature: d.signature,
      id: d.id,
      kind: d.kind,
      mac: d.displayMac,
      rssi: d.rssi,
      distanceMeters: d.distanceMeters,
      firstSeenMs: d.firstSeenMs,
      lastSeenMs: d.lastSeenMs,
      rotatingMacCount: d.rotatingMacCount,
      rawFrame: d.rawFrame,
    );

    notifier.value = [report, ...notifier.value];
    await _persist();
    return report;
  }

  static Future<void> updateFeedback(String reportId, String feedback) async {
    final updated = notifier.value.map((r) {
      if (r.reportId != reportId) return r;
      return r.copyWith(teamFeedback: feedback);
    }).toList();

    notifier.value = updated;
    await _persist();
  }


  // DOWNLOADS EXPORT HELPERS


  static String _safeTimestamp(DateTime t) {
    // Windows + Android friendly
    return t
        .toIso8601String()
        .replaceAll(":", "-")
        .replaceAll(".", "-");
  }

  static String _feet(double meters) => (meters * 3.28084).toStringAsFixed(1);

  static String _dtLocalString(DateTime dt) {
    // keeps it simple; user’s device locale/timezone will be used
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return "$y-$mo-$d $h:$mi:$s";
  }

  static String _formatCaseTxt(TrackerReport r) {
    final created = _dtLocalString(r.createdAt.toLocal());

    final firstSeen = r.firstSeenMs > 0
        ? _dtLocalString(DateTime.fromMillisecondsSinceEpoch(r.firstSeenMs).toLocal())
        : "N/A";
    final lastSeen = r.lastSeenMs > 0
        ? _dtLocalString(DateTime.fromMillisecondsSinceEpoch(r.lastSeenMs).toLocal())
        : "N/A";

    final mark = DeviceMarks.get(r.signature);
    final markLabel = (mark == DeviceMark.friendly)
        ? "Friendly"
        : "Suspect (user-marked)";

    final notes = (r.teamFeedback ?? "").trim();
    final notesBlock = notes.isEmpty ? "None." : notes;

    return """
LEO Find It Case Report
-----------------------

Report ID: ${r.reportId}
Created: $created

Device
------
Type/Kind: ${r.kind}
Signature: ${r.signature}
Device ID: ${r.id}
MAC: ${r.mac}

Detection Summary
-----------------
RSSI: ${r.rssi} dBm
Distance estimate: ${_feet(r.distanceMeters)} ft (${r.distanceMeters.toStringAsFixed(2)} m)
First seen: $firstSeen
Last seen:  $lastSeen
MAC rotations observed: ${r.rotatingMacCount}

User Classification
-------------------
Marked as: $markLabel

User Notes (no PII)
-------------------
$notesBlock

Raw BLE Payload (hex)
---------------------
${r.rawFrame.isEmpty ? "N/A" : r.rawFrame}

Disclaimer
----------
- RSSI and distance are estimates and can vary by environment (walls, bodies, and other interference).
- This report does not contain gps location.
""";
  }

  /// Saves a TEXT case report into Downloads/LEOFindIt/ via MediaStore.
  /// Returns saved content:// uri string.
  static Future<String> saveCaseReportTxtToDownloads(TrackerReport r) async {
    final safeTs = _safeTimestamp(r.createdAt);
    final filename = "leo_case_${safeTs}_${r.reportId}.txt";
    final content = _formatCaseTxt(r);

    final uri = await _storage.invokeMethod<String>(
      "saveToDownloads",
      {
        "fileName": filename,
        "mimeType": "text/plain",
        "content": content,
      },
    ) ??
        "";

    if (uri.isEmpty) throw Exception("Failed to save TXT to Downloads");

    final updated = notifier.value.map((x) {
      if (x.reportId != r.reportId) return x;
      return x.copyWith(exportedUriTxt: uri);
    }).toList();

    notifier.value = updated;
    await _persist();

    return uri;
  }

  /// Saves a RAW JSON evidence file into Downloads/LEOFindIt/ via MediaStore.
  /// Returns saved content:// uri string.
  static Future<String> saveRawJsonToDownloads(TrackerReport r) async {
    final safeTs = _safeTimestamp(r.createdAt);
    final filename = "leo_evidence_${safeTs}_${r.reportId}.json";
    final jsonPretty = const JsonEncoder.withIndent("  ").convert(r.toJson());

    final uri = await _storage.invokeMethod<String>(
      "saveToDownloads",
      {
        "fileName": filename,
        "mimeType": "application/json",
        "content": jsonPretty,
      },
    ) ??
        "";

    if (uri.isEmpty) throw Exception("Failed to save JSON to Downloads");

    final updated = notifier.value.map((x) {
      if (x.reportId != r.reportId) return x;
      return x.copyWith(exportedUriJson: uri);
    }).toList();

    notifier.value = updated;
    await _persist();

    return uri;
  }

  /// Delete a report from app list (local).
  /// If [alsoDeleteExportedFiles] is true, attempts to delete exported JSON/TXT too.
  static Future<void> deleteReport(
      String reportId, {
        bool alsoDeleteExportedFiles = false,
      }) async {
    String? uriJson;
    String? uriTxt;

    for (final r in notifier.value) {
      if (r.reportId == reportId) {
        uriJson = r.exportedUriJson;
        uriTxt = r.exportedUriTxt;
        break;
      }
    }

    notifier.value = notifier.value.where((r) => r.reportId != reportId).toList();
    await _persist();

    if (alsoDeleteExportedFiles) {
      final uris = [uriJson, uriTxt].whereType<String>().where((u) => u.isNotEmpty);
      for (final u in uris) {
        try {
          await _storage.invokeMethod<bool>("deleteFromDownloads", {"uri": u});
        } catch (_) {
          // best effort
        }
      }
    }
  }

  /// Clear all reports from app list.
  /// Optionally attempt deleting exported files too (best effort).
  static Future<void> clearAll({bool alsoDeleteExportedFiles = false}) async {
    final uris = alsoDeleteExportedFiles
        ? notifier.value
        .expand((r) => [r.exportedUriJson, r.exportedUriTxt])
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList()
        : <String>[];

    notifier.value = [];
    await _persist();

    if (alsoDeleteExportedFiles) {
      for (final u in uris) {
        try {
          await _storage.invokeMethod<bool>("deleteFromDownloads", {"uri": u});
        } catch (_) {}
      }
    }
  }
}
