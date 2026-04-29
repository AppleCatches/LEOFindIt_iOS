// ---------------------------
// leofindit / lib / advanced_scanner_view.dart
// ---------------------------
import 'package:flutter/material.dart';
import 'models.dart';
import 'search_page.dart';
import 'device_marks.dart';

class AdvancedScannerView extends StatelessWidget {
  final List<TrackerDevice> devices;
  final bool scanning;
  final DateTime? lastScanTime;

  const AdvancedScannerView({
    super.key,
    required this.devices,
    required this.scanning,
    required this.lastScanTime,
  });

  String get _status {
    if (scanning) return "Scanning…";
    if (lastScanTime == null) return "Idle";
    return "Scan stopped";
  }

  IconData _rssiIcon(int rssi) {
    if (rssi > -50) return Icons.signal_cellular_alt; // strongest
    if (rssi > -70) return Icons.signal_cellular_alt_rounded; // medium
    if (rssi > -85) return Icons.network_cell; // weak
    return Icons.signal_cellular_null; // no signal
  }

  String _rssiLabel(int rssi) {
    if (rssi > -50) return "Very close";
    if (rssi > -70) return "Near";
    if (rssi > -85) return "Far";
    return "Very far";
  }

  Color _kindColor(TrackerDevice d) {
    if (d.isLikelyAirTag) return Colors.red;
    if (d.isLikelyTile) return Colors.blue;
    if (d.isLikelySamsung) return Colors.purple;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final shown = devices;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Advanced Scanner"),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              _status,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: DeviceMarks.version,
                builder: (_, __, ___) {
                  final shownUnmarked = shown
                      .where((d) => DeviceMarks.getMark(d.signature) == null)
                      .toList();

                  return shownUnmarked.isEmpty
                      ? const Center(
                          child: Text(
                            "No devices detected yet.\nPress Start Scan to begin.",
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: shownUnmarked.length,
                          itemBuilder: (context, index) {
                            final d = shownUnmarked[index];
                            final name = d.displayName;
                            final id = d.id;
                            final rssi = d.rssi;
                            final distance = d.distanceFeet;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SearchPage(device: d),
                                    ),
                                  );
                                },
                                leading: Icon(
                                  _rssiIcon(rssi),
                                  color: _kindColor(d),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _kindColor(d),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("ID: $id"),
                                    Text(
                                      "RSSI: $rssi dBm • ${_rssiLabel(rssi)}",
                                    ),
                                    Text(
                                      "Distance: ${distance.toStringAsFixed(2)} ft • ${(distance / 3.28084).toStringAsFixed(2)} m",
                                    ),
                                    Text("UUID: ${d.displayUuid}"),
                                    Text("Rotations: ${d.rotatingMacCount}"),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
