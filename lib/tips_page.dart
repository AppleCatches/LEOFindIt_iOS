import 'package:flutter/material.dart';

// A tips page that provides users with practical advice and best practices for effectively using the app
class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  // Create a tip item in the tips page
  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 7),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // The UI of the tips page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tips')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Scanning Tips',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _tip(
            'Leave the phone still and alone with a package that could have a tag.',
          ),
          _tip(
            'Move slowly when changing scan positions so signal changes are easier to interpret.',
          ),
          _tip(
            'Re-scan from multiple positions to see whether the same device remains strong nearby.',
          ),
          _tip(
            'A stronger RSSI usually suggests the device is closer, but walls, metal, and containers can distort readings.',
          ),
          _tip(
            'Use the advanced scanner to compare UUID, RSSI, and distance instead of relying on one reading alone.',
          ),
          _tip(
            'If many devices are present, narrow results with RSSI filtering and shorter distance ranges.',
          ),
          _tip(
            'Document the UUID shown by the app, not a MAC address, because iOS does not expose MAC addresses through CoreBluetooth.',
          ),
          _tip(
            'Treat distance estimates as approximate. Real-world radio conditions can shift the reported distance.',
          ),
          _tip(
            'Signal Blockers: Metal heavily blocks Bluetooth signals. A tracker hidden inside a metal container or vehicle frame may show a very weak signal or be completely undetectable. Cardboard causes minor signal drops.',
          ),
          _tip(
            'Due to the nature of rolling identifiers in these tags, it is possible that the same tag could show up in the list twice. The first appearance will show as older, and the second instance will show up more recently.',
          ),
          const SizedBox(height: 12),
          const Text(
            'More tips can be added later as needed.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
