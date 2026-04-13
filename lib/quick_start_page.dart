import 'package:flutter/material.dart';

// A quick start guide for new users, outlining the basic steps on how to use the app
class QuickStartPage extends StatelessWidget {
  const QuickStartPage({super.key});

  // In the quick start guide, display the step number, title, and description
  Widget _step(int number, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text('$number'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The UI of the quick start page
  // Also includes an tip about how the app identifies devices on iOS
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Start')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Quick Start for New Users',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Use this when you need a fast first scan for a possible hidden Bluetooth tracker.',
          ),
          const SizedBox(height: 20),
          _step(
            1,
            'Open the scan screen',
            'Go to the main scanner page and make sure Bluetooth permissions are allowed.',
          ),
          _step(
            2,
            'Place the phone near the target area',
            'Stand near the vehicle, package, bag, or room you want to inspect before starting a scan.',
          ),
          _step(
            3,
            'Start Scan',
            'Tap Start Scan. The app is designed around a timed scan session and will collect nearby Bluetooth tracker activity.',
          ),
          _step(
            4,
            'Keep the phone as still as possible',
            'Minimize movement while scanning so the signal readings are more stable and easier to compare.',
          ),
          _step(
            5,
            'Review nearby detections',
            'Look at the main results first. Focus on suspicious devices with stronger RSSI and shorter estimated distance.',
          ),
          _step(
            6,
            'Tap a device for more details',
            'Open a device entry to inspect it further and decide whether it should be treated as undesignated, friendly, or suspect.',
          ),
          _step(
            7,
            'Use filters if needed',
            'Adjust distance, RSSI, and sorting if the area has too many devices or if you want to narrow results.',
          ),
          _step(
            8,
            'Repeat scan closer to the suspected object',
            'Run another scan from a closer position to compare signal strength and confirm whether the device remains nearby.',
          ),
          _step(
            9,
            'Document findings',
            'Record the device type shown by the app, the UUID displayed in the app, the signal strength, and the context of where it was found.',
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Important',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'On iOS, the app uses a UUID-based identifier from CoreBluetooth. It does not use MAC addresses.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
