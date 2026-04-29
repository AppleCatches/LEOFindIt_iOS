import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  // Hidden / dismissed undesignated tags (for HiddenTagsPage)
  static final Set<String> _dismissedUndesignated = <String>{};

  static bool _loaded = false;

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

  static bool isUndesignatedDismissed(String stableKey) {
    return _dismissedUndesignated.contains(stableKey);
  }

  static Set<String> get dismissedUndesignatedKeys =>
      Set<String>.from(_dismissedUndesignated);

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
    await _save();
  }

  static Future<void> clear() async {
    _marks.clear();
    version.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  static Future<void> clearByMark(DeviceMark mark) async {
    final keys = _marks.entries
        .where((e) => e.value == mark)
        .map((e) => e.key)
        .toList();

    for (final k in keys) {
      _marks.remove(k);
    }

    version.value++;
    await _save();
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
