// lib/distance_page.dart

import 'package:flutter/material.dart';
import 'models.dart';
import 'search_page.dart';
import 'advanced_scanner_view.dart';
import 'device_marks.dart';

// The DistancePage widget displays a list of nearby tracker devices with their estimated distances and RSSI values
// Also provides buttons to show all detected devices and to start or stop scanning for devices
class DistancePage extends StatelessWidget {
  final List<TrackerDevice> nearDevices;
  final List<TrackerDevice> allTrackedDevices;
  final bool scanning;
  final Future<void> Function() onRescan;
  final DateTime? lastScanTime;
  final String scanCountdownLabel;
  final Future<void> Function() onRefresh;

  // Constructor for the DistancePage widget to allow the page to display relevant information about detected devices and provide functionality for managing scans
  const DistancePage({
    super.key,
    required this.nearDevices,
    required this.allTrackedDevices,
    required this.scanning,
    required this.onRescan,
    required this.lastScanTime,
    required this.scanCountdownLabel,
    required this.onRefresh,
  });

  // Format the last scan time into a user-friendly string, displaying the time in a 12-hour format with AM/PM
  String _formatTime() {
    if (lastScanTime == null) return '';
    int hour = lastScanTime!.hour % 12;
    if (hour == 0) hour = 12;
    final min = lastScanTime!.minute.toString().padLeft(2, '0');
    final am = lastScanTime!.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $am';
  }

  // Helper function to determine the number of signal bars to display based on the RSSI value
  int _bars(int rssi) {
    if (rssi >= -55) return 5;
    if (rssi >= -65) return 4;
    if (rssi >= -75) return 3;
    if (rssi >= -85) return 2;
    return 1;
  }

  // Build the UI for the DistancePage, including buttons for showing all devices and starting/stopping scans, as well as a list of nearby devices with their details
  @override
  Widget build(BuildContext context) {
    final track = nearDevices;

    // If there are no nearby devices detected, the page will display a message indicating that no trackers have been detected
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            children: [
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.search,
                  size: 22,
                  color: Colors.blueAccent,
                ),
                label: const Text(
                  'Show All Devices',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.grey.shade50,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: Colors.blueAccent.withOpacity(0.25),
                      width: 1.2,
                    ),
                  ),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => FractionallySizedBox(
                      heightFactor: 0.92,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: AdvancedScannerView(
                          devices: allTrackedDevices,
                          scanning: scanning,
                          lastScanTime: lastScanTime,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(
                  scanning ? Icons.stop : Icons.play_arrow,
                  size: 28,
                  color: Colors.blueAccent,
                ),
                label: Text(
                  scanning ? 'Stop Scan' : 'Start Scan',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade50,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: Colors.blueAccent.withOpacity(0.25),
                      width: 1.2,
                    ),
                  ),
                ),
                onPressed: () async {
                  await onRescan();
                },
              ),
              const SizedBox(height: 10),
              Text(
                scanning
                    ? 'Scanning… $scanCountdownLabel'
                    : lastScanTime == null
                    ? 'No scans yet'
                    : 'Last scan ${_formatTime()}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: DeviceMarks.version,
            builder: (_, __, ___) {
              final visibleTrack = track
                  .where((d) => DeviceMarks.getMark(d.signature) == null)
                  .toList();

              return RefreshIndicator(
                onRefresh: onRefresh,
                child: visibleTrack.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'No trackers detected',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: visibleTrack.length,
                        itemBuilder: (_, i) {
                          final d = visibleTrack[i];
                          // Notice we use getMark() here now!
                          final mark = DeviceMarks.getMark(d.signature);
                          final isMarked = mark != null;

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SearchPage(device: d),
                              ),
                            ),
                            child: Opacity(
                              opacity: isMarked ? 0.45 : 1.0,
                              child: Card(
                                color: isMarked ? Colors.grey.shade200 : null,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 13,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.signal_cellular_alt_rounded,
                                        size: 46,
                                        color: isMarked
                                            ? Colors.grey
                                            : Colors.blueAccent,
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              d.displayName,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                                color: isMarked
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Distance: ${d.distanceFeet.toStringAsFixed(2)} ft • ${(d.distanceFeet / 3.28084).toStringAsFixed(2)} m',
                                              style: TextStyle(
                                                color: isMarked
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                            ),
                                            Text(
                                              'RSSI: ${d.rssi} dBm',
                                              style: TextStyle(
                                                color: isMarked
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                            ),
                                            Text(
                                              'UUID: ${d.displayUuid}',
                                              style: TextStyle(
                                                color: isMarked
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: List.generate(
                                                5,
                                                (idx) => Icon(
                                                  Icons.signal_cellular_alt,
                                                  size: 20,
                                                  color:
                                                      idx <
                                                          _bars(
                                                            d.smoothedRssi
                                                                .round(),
                                                          )
                                                      ? (isMarked
                                                            ? Colors.grey
                                                            : Colors.green)
                                                      : Colors.grey.shade300,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}
