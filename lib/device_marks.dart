import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeviceMark {
  undesignated,
  friendly,
  nonsuspect,
  suspect,
}

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

class DeviceMarks {
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static const String _prefsKey = 'device_marks_v2';
  static const String _dismissedUndesignatedPrefsKey =
      'dismissed_undesignated_v1';

  static final Map<String, DeviceMark> _marks = {};
  static final Set<String> _dismissedUndesignated = <String>{};

  static bool _loaded = false;

  static Future<void> init() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(raw));
        _marks.clear();

        decoded.forEach((key, value) {
          switch (value) {
            case 'friendly':
              _marks[key] = DeviceMark.friendly;
              break;
            case 'nonsuspect':
              _marks[key] = DeviceMark.nonsuspect;
              break;
            case 'suspect':
              _marks[key] = DeviceMark.suspect;
              break;
            case 'unknown':
            case 'undesignated':
            default:
              _marks[key] = DeviceMark.undesignated;
              break;
          }
        });
      } catch (_) {
        _marks.clear();
      }
    }

    final dismissedRaw = prefs.getStringList(_dismissedUndesignatedPrefsKey);
    _dismissedUndesignated
      ..clear()
      ..addAll(dismissedRaw ?? const <String>[]);

    _loaded = true;
    version.value++;
  }

  static DeviceMark get(String stableKey) {
    return _marks[stableKey] ?? DeviceMark.undesignated;
  }

  static bool isUndesignatedDismissed(String stableKey) {
    return _dismissedUndesignated.contains(stableKey);
  }

  static Set<String> get dismissedUndesignatedKeys =>
      Set<String>.from(_dismissedUndesignated);

  static Future<void> set(String stableKey, DeviceMark mark) async {
    _marks[stableKey] = mark;

    // If the user classifies the device, it should not stay hidden
    // by an old undesignated swipe-dismiss.
    _dismissedUndesignated.remove(stableKey);

    version.value++;
    await _save();
    await _saveDismissedUndesignated();
  }

  static Future<void> remove(String stableKey) async {
    _marks.remove(stableKey);
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

  static Future<void> dismissUndesignated(String stableKey) async {
    _dismissedUndesignated.add(stableKey);
    version.value++;
    await _saveDismissedUndesignated();
  }

  static Future<void> restoreUndesignated(String stableKey) async {
    if (_dismissedUndesignated.remove(stableKey)) {
      version.value++;
      await _saveDismissedUndesignated();
    }
  }

  static Future<void> clearDismissedUndesignated() async {
    _dismissedUndesignated.clear();
    version.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedUndesignatedPrefsKey);
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, String>{};

    _marks.forEach((key, value) {
      data[key] = value.name;
    });

    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  static Future<void> _saveDismissedUndesignated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dismissedUndesignatedPrefsKey,
      _dismissedUndesignated.toList(),
    );
  }
}
// Only Using this so the unknown / friendly logic
// Can be saved across pages for the marks on
// The search page to the Identification page
// And so saved categories persists
// Issue that came up that I want to remember:
// Never let a newly created page see more data than an earlier / older page
// If an output wasn't valid on say the scan page it won't be valid on another page
