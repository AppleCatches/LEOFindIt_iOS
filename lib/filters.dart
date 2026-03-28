import 'package:flutter/foundation.dart';

enum SortMode { recent, distanceAsc }

// State management for the filters used in the app, allowing users to customize how detected devices are filtered and sorted based on distance, RSSI, and other criteria
class FiltersState {
  final double maxAdvancedDistanceFt;
  final double maxMainDistanceFt; // default 15 ft
  final int minRssi;
  // final bool hideConnectableNonTrackers;

  final bool filterByRssi;
  final int rssiThreshold;
  final SortMode sortMode;

  // Constructor for creating a FiltersState instance with all filter settings
  const FiltersState({
    required this.maxAdvancedDistanceFt,
    required this.maxMainDistanceFt,
    required this.minRssi,
    // required this.hideConnectableNonTrackers,
    required this.filterByRssi,
    required this.rssiThreshold,
    required this.sortMode,
  });

  // Create a copy of the current FiltersState with updated values for any provided parameters, allowing for easy state updates while maintaining immutability
  FiltersState copyWith({
    double? maxAdvancedDistanceFt,
    double? maxMainDistanceFt,
    int? minRssi,
    // bool? hideConnectableNonTrackers,
    bool? filterByRssi,
    int? rssiThreshold,
    SortMode? sortMode,
  }) {
    // Return a new FiltersState instance with updated values based on the provided parameters, while keeping unchanged values the same as the current instance
    return FiltersState(
      maxAdvancedDistanceFt:
          maxAdvancedDistanceFt ?? this.maxAdvancedDistanceFt,
      maxMainDistanceFt: maxMainDistanceFt ?? this.maxMainDistanceFt,
      minRssi: minRssi ?? this.minRssi,
      // hideConnectableNonTrackers:
      // hideConnectableNonTrackers ?? this.hideConnectableNonTrackers,
      filterByRssi: filterByRssi ?? this.filterByRssi,
      rssiThreshold: rssiThreshold ?? this.rssiThreshold,
      sortMode: sortMode ?? this.sortMode,
    );
  }
}

// The FiltersModel class manages the current state of the filters using a ValueNotifier, allowing the app to reactively update the UI whenever filter settings change
class FiltersModel {
  static final ValueNotifier<FiltersState> notifier =
      ValueNotifier<FiltersState>(
        const FiltersState(
          maxAdvancedDistanceFt: 100.0, // 100 ft
          maxMainDistanceFt: 15.0, // 15 ft
          minRssi: -95,
          // hideConnectableNonTrackers: true,
          filterByRssi: false,
          rssiThreshold: -70,
          sortMode: SortMode.distanceAsc,
        ),
      );

  static FiltersState get state => notifier.value;

  static void setMaxAdvancedDistanceFt(double v) {
    notifier.value = notifier.value.copyWith(maxAdvancedDistanceFt: v);
  }

  static void setMaxMainDistanceFt(double v) {
    notifier.value = notifier.value.copyWith(maxMainDistanceFt: v);
  }

  static void setMinRssi(int v) {
    notifier.value = notifier.value.copyWith(minRssi: v);
  }

  // static void setHideConnectableNonTrackers(bool v) {
  // notifier.value = notifier.value.copyWith(hideConnectableNonTrackers: v);
  // }

  static void setFilterByRssi(bool v) {
    notifier.value = notifier.value.copyWith(filterByRssi: v);
  }

  static void setRssiThreshold(int v) {
    notifier.value = notifier.value.copyWith(rssiThreshold: v);
  }

  static void setSortMode(SortMode mode) {
    notifier.value = notifier.value.copyWith(sortMode: mode);
  }

  static void apply({
    required double maxMainDistanceFt,
    required double maxAdvancedDistanceFt,
    required int minRssi,
    // required bool hideConnectableNonTrackers,
    required bool filterByRssi,
    required int rssiThreshold,
    required SortMode sortMode,
  }) {
    notifier.value = FiltersState(
      maxAdvancedDistanceFt: maxAdvancedDistanceFt,
      maxMainDistanceFt: maxMainDistanceFt,
      minRssi: minRssi,
      // hideConnectableNonTrackers: hideConnectableNonTrackers,
      filterByRssi: filterByRssi,
      rssiThreshold: rssiThreshold,
      sortMode: sortMode,
    );
  }
}
