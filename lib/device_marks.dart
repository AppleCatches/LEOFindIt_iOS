import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Enum representing the mark/status of a device
enum DeviceMark { suspect, friendly, nonsuspect }

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
      orElse: () => DeviceMark.nonsuspect,
    ),
    json['customName'] as String?,
  );
}

// Manage the marks/statuses of devices, allowing retrieval, setting, and clearing of marks
class DeviceMarks {
  static final Map<String, DeviceMetadata> _marks = {};
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  // Load saved data on app start
  static Future<void> init() async {
    try {
      final file = await _file();
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        decoded.forEach((key, value) {
          _marks[key] = DeviceMetadata.fromJson(value);
        });
        version.value++;
      }
    } catch (e) {
      debugPrint("Error loading device marks: $e");
    }
  }

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/leo_device_marks.json");
  }

  static Future<void> _save() async {
    try {
      final file = await _file();
      final jsonMap = _marks.map((key, value) => MapEntry(key, value.toJson()));
      await file.writeAsString(jsonEncode(jsonMap));
    } catch (e) {
      debugPrint("Error saving device marks: $e");
    }
  }

  static DeviceMark? getMark(String signature) => _marks[signature]?.mark;
  static String? getName(String signature) => _marks[signature]?.customName;

  static void setMark(String signature, DeviceMark mark) {
    final existingName = _marks[signature]?.customName;
    _marks[signature] = DeviceMetadata(mark, existingName);
    version.value++;
    _save();
  }

  static void setName(String signature, String name) {
    final existingMark = _marks[signature]?.mark ?? DeviceMark.nonsuspect;
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
}
