import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Enum representing the mark/status of a device
enum DeviceMark { suspect, friendly, undesignated, nonsuspect }

extension DeviceMarkX on DeviceMark {
  String get label {
    switch (this) {
      case DeviceMark.undesignated:
        return 'Undesignated';
      case DeviceMark.friendly:
        return 'Friendly';
      case DeviceMark.nonsuspect:
        return 'Nonsuspect';
      case DeviceMark.suspect:
        return 'Suspect';
    }
  }
}

class DeviceMetadata {
  final DeviceMark mark;
  final String? customName;

  DeviceMetadata(this.mark, this.customName);

  Map<String, dynamic> toJson() => {
    'mark': mark.name,
    'customName': customName,
  };

  static DeviceMetadata fromJson(Map<String, dynamic> json) => DeviceMetadata(
    DeviceMark.values.firstWhere(
      (e) => e.name == json['mark'],
      orElse: () => DeviceMark.undesignated,
    ),
    json['customName'] as String?,
  );
}

// Manage the marks/statuses of devices + hidden (dismissed) undesignated tags
class DeviceMarks {
  static final Map<String, DeviceMetadata> _marks = {};
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  // Hidden / dismissed undesignated tags (for HiddenTagsPage)
  static final Set<String> _dismissedUndesignated = <String>{};

  // Load saved data on app start
  static Future<void> init() async {
    try {
      final file = await _file();
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);

        // Load marked devices
        decoded.forEach((key, value) {
          if (key != '__dismissed_undesignated__') {
            _marks[key] = DeviceMetadata.fromJson(value);
          }
        });

        // Load hidden/dismissed undesignated keys
        if (decoded.containsKey('__dismissed_undesignated__')) {
          _dismissedUndesignated.addAll(
            List<String>.from(decoded['__dismissed_undesignated__']),
          );
        }

        version.value++;
      }
    } catch (e) {
      debugPrint("Error loading device marks: $e");
    }
  }

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/leo_device_marks_v2.json");
  }

  static Future<void> _save() async {
    try {
      final file = await _file();
      final jsonMap = _marks.map((key, value) => MapEntry(key, value.toJson()));

      // Add dismissed keys to the same file
      final fullData = Map<String, dynamic>.from(jsonMap);
      fullData['__dismissed_undesignated__'] = _dismissedUndesignated.toList();

      await file.writeAsString(jsonEncode(fullData));
    } catch (e) {
      debugPrint("Error saving device marks: $e");
    }
  }

  static DeviceMark? getMark(String signature) => _marks[signature]?.mark;
  static String? getName(String signature) => _marks[signature]?.customName;

  static void setMark(String signature, DeviceMark? mark) {
    final existingName = _marks[signature]?.customName;
    if (mark == null) {
      if (existingName == null) {
        _marks.remove(signature);
      } else {
        _marks[signature] = DeviceMetadata(
          DeviceMark.undesignated,
          existingName,
        );
      }
    } else {
      _marks[signature] = DeviceMetadata(mark, existingName);
    }
    version.value++;
    _save();
  }

  static void setName(String signature, String name) {
    final existingMark = _marks[signature]?.mark ?? DeviceMark.undesignated;
    _marks[signature] = DeviceMetadata(
      existingMark,
      name.trim().isEmpty ? null : name.trim(),
    );
    version.value++;
    _save();
  }

  static void clear(String signature) {
    _marks.remove(signature);
    version.value++;
    _save();
  }

  // ─────────────────────────────────────────────────────────────
  // Hidden / Dismissed Undesignated support (used by HiddenTagsPage)
  // ─────────────────────────────────────────────────────────────
  static Set<String> get dismissedUndesignatedKeys =>
      Set<String>.from(_dismissedUndesignated);

  static Future<void> dismissUndesignated(String stableKey) async {
    _dismissedUndesignated.add(stableKey);
    version.value++;
    await _save();
  }

  static Future<void> restoreUndesignated(String stableKey) async {
    if (_dismissedUndesignated.remove(stableKey)) {
      version.value++;
      await _save();
    }
  }

  static Future<void> clearDismissedUndesignated() async {
    _dismissedUndesignated.clear();
    version.value++;
    await _save();
  }
}
