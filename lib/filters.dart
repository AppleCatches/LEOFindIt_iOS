import 'package:flutter/foundation.dart';

enum SortMode {
  strongestHold,
  distanceAsc,
  recent,
}

enum MissionMode {
  packageSearch,
  wideAreaHiddenTag,
}

class FiltersState {
  final bool filterByRssi;
  final int rssiThreshold;
  final SortMode sortMode;
  final MissionMode missionMode;
  final double maxMainDistanceFt;
  final double maxAdvancedDistanceFt;
  final int minRssi;

  const FiltersState({
    required this.filterByRssi,
    required this.rssiThreshold,
    required this.sortMode,
    required this.missionMode,
    this.maxMainDistanceFt = 50.0,
    this.maxAdvancedDistanceFt = 200.0,
    this.minRssi = -100,
  });

  FiltersState copyWith({
    bool? filterByRssi,
    int? rssiThreshold,
    SortMode? sortMode,
    MissionMode? missionMode,
    double? maxMainDistanceFt,
    double? maxAdvancedDistanceFt,
    int? minRssi,
  }) {
    return FiltersState(
      filterByRssi: filterByRssi ?? this.filterByRssi,
      rssiThreshold: rssiThreshold ?? this.rssiThreshold,
      sortMode: sortMode ?? this.sortMode,
      missionMode: missionMode ?? this.missionMode,
      maxMainDistanceFt: maxMainDistanceFt ?? this.maxMainDistanceFt,
      maxAdvancedDistanceFt: maxAdvancedDistanceFt ?? this.maxAdvancedDistanceFt,
      minRssi: minRssi ?? this.minRssi,
    );
  }
}

class FiltersModel {
  static final ValueNotifier<FiltersState> notifier =
  ValueNotifier<FiltersState>(
    const FiltersState(
      filterByRssi: true,
      rssiThreshold: -85,
      sortMode: SortMode.strongestHold,
      missionMode: MissionMode.packageSearch,
    ),
  );

  static FiltersState get state => notifier.value;

  static void setFilterByRssi(bool v) {
    notifier.value = notifier.value.copyWith(filterByRssi: v);
  }

  static void setRssiThreshold(int v) {
    notifier.value = notifier.value.copyWith(rssiThreshold: v);
  }

  static void setSortMode(SortMode mode) {
    notifier.value = notifier.value.copyWith(sortMode: mode);
  }

  static void setMissionMode(MissionMode mode) {
    notifier.value = notifier.value.copyWith(missionMode: mode);
  }

  static void applyMissionPreset(MissionMode mode) {
    switch (mode) {
      case MissionMode.packageSearch:
        notifier.value = const FiltersState(
          filterByRssi: true,
          rssiThreshold: -78,
          sortMode: SortMode.strongestHold,
          missionMode: MissionMode.packageSearch,
        );
        break;
      case MissionMode.wideAreaHiddenTag:
        notifier.value = const FiltersState(
          filterByRssi: true,
          rssiThreshold: -92,
          sortMode: SortMode.strongestHold,
          missionMode: MissionMode.wideAreaHiddenTag,
        );
        break;
    }
  }

  static void apply({
    required double maxMainDistanceFt,
    required double maxAdvancedDistanceFt,
    required int minRssi,
    required bool filterByRssi,
    required int rssiThreshold,
    required SortMode sortMode,
  }) {
    notifier.value = FiltersState(
      filterByRssi: filterByRssi,
      rssiThreshold: rssiThreshold,
      sortMode: sortMode,
      missionMode: notifier.value.missionMode,
      maxMainDistanceFt: maxMainDistanceFt,
      maxAdvancedDistanceFt: maxAdvancedDistanceFt,
      minRssi: minRssi,
    );
  }
}
