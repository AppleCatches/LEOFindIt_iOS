import 'package:flutter/material.dart';
import 'models.dart';
import 'app_drawer.dart';

class TrackerDevicePage extends StatelessWidget {
  final TrackerDevice device;

  const TrackerDevicePage({super.key, required this.device});

  String _ageLabel(int lastSeenMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final s = ((now - lastSeenMs) / 1000).clamp(0, 999999).toDouble();
    if (s < 60) return "${s.toStringAsFixed(1)}s ago";
    final m = (s / 60).floor();
    final rs = (s - m * 60).floor();
    return "${m}m ${rs}s ago";
  }

  IconData _iconFor(TrackerDevice d) {
    if (d.isLikelyAirTag) return Icons.apple;
    if (d.isLikelyTile) return Icons.location_searching;
    if (d.isLikelySamsung) return Icons.radio_button_checked;
    return Icons.bluetooth;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(device.displayName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Center(
              child: Icon(_iconFor(device), size: 96),
            ),
            const SizedBox(height: 24),
            _row('Type', device.displayName),
            _row('Kind', device.kind),
            _row('MAC Address', device.displayMac),
            _row('Last seen', _ageLabel(device.lastSeenMs)),
            _row('Distance', '${device.distance.toStringAsFixed(2)} m'),
            _row('Distance (ft)', device.distanceFtLabel),
            _row('RSSI', '${device.rssi} dBm'),
            _row('RSSI (smoothed)', device.smoothedRssi.toStringAsFixed(1)),
            _row('Sightings', device.sightings.toString()),
            _row('MAC rotations', device.rotatingMacCount.toString()),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Raw BLE Payload (hex)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              device.rawFrame.isEmpty ? 'N/A' : device.rawFrame,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
// Page used for saving state of unknow / friendly
// Devices being marked on the distance page
