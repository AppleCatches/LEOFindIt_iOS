import 'package:flutter/foundation.dart';

enum SortMode { recent, distanceAsc }

// State management for the filters used in the app, allowing users to customize how detected devices are filtered and sorted based on distance, RSSI, and other criteria
class FiltersState {
  final double maxAdvancedDistanceM;
  final double maxMainDistanceM; // e.g. 3.05 m = 10 ft
  final int minRssi;
  // final bool hideConnectableNonTrackers;

  final bool filterByRssi;
  final int rssiThreshold;
  final SortMode sortMode;
  
  // Constructor for creating a FiltersState instance with all filter settings
  const FiltersState({
    required this.maxAdvancedDistanceM,
    required this.maxMainDistanceM,
    required this.minRssi,
    // required this.hideConnectableNonTrackers,
    required this.filterByRssi,
    required this.rssiThreshold,
    required this.sortMode,
  });
  
  // Create a copy of the current FiltersState with updated values for any provided parameters, allowing for easy state updates while maintaining immutability
  FiltersState copyWith({
    double? maxAdvancedDistanceM,
    double? maxMainDistanceM,
    int? minRssi,
    // bool? hideConnectableNonTrackers,
    bool? filterByRssi,
    int? rssiThreshold,
    SortMode? sortMode,
  }) {
    // Return a new FiltersState instance with updated values based on the provided parameters, while keeping unchanged values the same as the current instance
    return FiltersState(
      maxAdvancedDistanceM: maxAdvancedDistanceM ?? this.maxAdvancedDistanceM,
      maxMainDistanceM: maxMainDistanceM ?? this.maxMainDistanceM,
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
          maxAdvancedDistanceM: 20.0,
          maxMainDistanceM: 3.05, // 10 ft
          minRssi: -95,
          // hideConnectableNonTrackers: true,
          filterByRssi: false,
          rssiThreshold: -70,
          sortMode: SortMode.distanceAsc,
        ),
      );

  static FiltersState get state => notifier.value;

  static void setMaxAdvancedDistanceM(double v) {
    notifier.value = notifier.value.copyWith(maxAdvancedDistanceM: v);
  }

  static void setMaxMainDistanceM(double v) {
    notifier.value = notifier.value.copyWith(maxMainDistanceM: v);
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
    required double maxMainDistanceM,
    required double maxAdvancedDistanceM,
    required int minRssi,
    // required bool hideConnectableNonTrackers,
    required bool filterByRssi,
    required int rssiThreshold,
    required SortMode sortMode,
  }) {
    notifier.value = FiltersState(
      maxAdvancedDistanceM: maxAdvancedDistanceM,
      maxMainDistanceM: maxMainDistanceM,
      minRssi: minRssi,
      // hideConnectableNonTrackers: hideConnectableNonTrackers,
      filterByRssi: filterByRssi,
      rssiThreshold: rssiThreshold,
      sortMode: sortMode,
    );
  }
}
