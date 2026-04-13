import 'package:flutter/material.dart';

// A help page that provides detailed instructions and explanations for using the advanced search and filter features of the app
class AdvancedSearchHelpPage extends StatelessWidget {
  const AdvancedSearchHelpPage({super.key});

  // Create an item in the advanced search help page, displaying the title and description
  Widget _item(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }

  // Construct the UI of the advanced search help page along with practical tips on how to use these features
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Search')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Filter Instructions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _item(
            'Main list distance (meters)',
            'Controls which detected devices appear in the main nearby list. Lower values narrow the list to the closest devices only.',
          ),
          _item(
            'Advanced list distance (meters)',
            'Controls how far out the advanced scanner view will include devices. Use a larger distance when you want a wider sweep of the area.',
          ),
          _item(
            'Minimum RSSI',
            'Sets the minimum signal strength floor. More negative values allow weaker, farther signals. Less negative values keep the list focused on stronger signals.',
          ),
          // still detects non-trackers
          /*
          _item(
            'Hide connectable non-trackers',
            'Reduces clutter by hiding connectable devices that are less likely to be the tracker types you care about.',
          ),
          */
          _item(
            'Filter by RSSI',
            'Shows only devices that are stronger than the threshold you set. This is useful when you want to focus on the devices most likely to be physically near you.',
          ),
          _item(
            'RSSI threshold',
            'Use this to define how strong a signal must be before it is shown. Less negative means stronger and usually closer. More negative means weaker and usually farther away.',
          ),
          _item(
            'Sort: Most recently seen',
            'Keeps the newest detections near the top. This is helpful when the environment changes frequently during the scan.',
          ),
          _item(
            'Sort: By distance',
            'Sorts devices from closest estimated distance to farthest estimated distance.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Practical use',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'If the screen is crowded, turn on RSSI filtering and raise the threshold toward stronger signals. If you are searching a vehicle or package, reduce the distance range and re-scan from a closer position.',
                  ),
                  Text(
                    'If searching a vehicle or metal container, be aware that metal blocks signals. You may need to reduce the minimum RSSI threshold and scan from multiple close angles to detect hidden devices.',
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
