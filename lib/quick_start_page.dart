// lib/quick_start_page.dart
import 'package:flutter/material.dart';
import 'app_tutorial.dart';

class QuickStartPage extends StatelessWidget {
  const QuickStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quick Start Guide',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Welcome to LeoFindIt',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'LEO Edition – Bluetooth Tracker Detection',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Colors.blueAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),

          const _Step(
            number: '1',
            title: 'Start a Scan',
            description:
                'Tap the large blue "Start Scan" button on the main screen. Hold your phone near the suspected area or package.',
          ),
          const _Step(
            number: '2',
            title: 'Watch for Trackers',
            description:
                'Detected devices appear instantly with signal bars, distance estimate, and UUID.',
          ),
          const _Step(
            number: '3',
            title: 'Classify the Device',
            description:
                'Tap any tracker → swipe the tabs at the bottom to mark it as Suspect (red), Friendly (green), Nonsuspect (blue), or Undesignated.',
          ),
          const _Step(
            number: '4',
            title: 'Use Mission Profiles',
            description:
                'Choose "Sealed package search" or "Known-area tag hunt" from the chips at the top to automatically adjust filters.',
          ),
          const _Step(
            number: '5',
            title: 'Open the Drawer',
            description:
                'Tap the menu icon (☰) for Filters, Reports, Advanced Features, and full LEO Guidance.',
          ),
<<<<<<< HEAD
          const _Step(
            number: '6',
            title: 'Need Help?',
            description:
                'Tap any tracker for real-time proximity pulsing, or go to LEO Guidance for evidence handling steps and Apple preservation instructions.',
=======
          /*
          _step(
            6,
            'Open Show All Devices / Advanced Scanner',
            'Use the advanced view to inspect more device details such as RSSI, estimated distance, UUID, and device type.',
          ),
          */
          _step(
            6,
            'Tap a device for more details',
            'Open a device entry to inspect it further and decide whether it should be treated as undesignated, friendly, or suspect.',
>>>>>>> parent of bc38b4d (can finally read airtags)
          ),

          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.school_outlined),
            label: const Text('Run Full Interactive Tutorial'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // The tutorial is triggered from main.dart when replayed
              // This button simply closes and lets the user reopen the drawer to replay
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Open the drawer and tap "Replay Tutorial" to begin',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 60),
          const Center(
            child: Text(
              'Built for Law Enforcement\nFlorida Gulf Coast University',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  const _Step({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 15, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
