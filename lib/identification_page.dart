// lib/identification_page.dart

import 'package:flutter/material.dart';
import 'models.dart';
import 'device_marks.dart';
import 'search_page.dart';

// The IdentificationPage widget displays a list of detected tracker devices categorized as Friendly, Unknown, or Suspect
// Designed to help users quickly identify and manage detected devices, providing clear categorization and easy access to device details
class IdentificationPage extends StatelessWidget {
  final List<TrackerDevice> devices;

  const IdentificationPage({required this.devices, super.key});

  // Build the UI for the IdentificationPage, categorizing detected devices into Friendly, Unknown, and Suspect sections
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: DeviceMarks.version,
      builder: (_, __, ___) {
        final Map<String, TrackerDevice> unique = {};
        for (final d in devices) {
          unique[d.signature] = d;
        }

        final nowMs = DateTime.now().millisecondsSinceEpoch;

        final qualified = unique.values.where((d) {
          if (d.distance <= 0) return false;

          final mark = DeviceMarks.getMark(d.signature);

          if (mark == DeviceMark.suspect ||
              mark == DeviceMark.friendly ||
              mark == DeviceMark.nonsuspect) {
            return true;
          }

          // If the device has been seen within the last 30 seconds, it is relevant for display even if it doesn't have a mark
          if (nowMs - d.lastSeenMs > 30 * 1000) return false;
          return true;
        }).toList();

        // Change lists to reflect new categories
        final suspect = <TrackerDevice>[];
        final friendly = <TrackerDevice>[];
        final nonsuspect = <TrackerDevice>[];

        for (final d in qualified) {
          final mark = DeviceMarks.getMark(d.signature);
          if (mark == DeviceMark.suspect) {
            suspect.add(d);
          } else if (mark == DeviceMark.friendly) {
            friendly.add(d);
          } else if (mark == DeviceMark.nonsuspect) {
            // Replaced 'unknown'
            nonsuspect.add(d);
          }
        }

        // Update the ListView children order
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _sectionTitle('Suspect'),
            if (suspect.isEmpty)
              _emptyHint('No suspect devices yet')
            else
              ...suspect.map((d) => _tile(context, d)),
            const SizedBox(height: 24),

            _sectionTitle('Friendly'),
            if (friendly.isEmpty)
              _emptyHint('No friendly devices yet')
            else
              ...friendly.map((d) => _tile(context, d)),
            const SizedBox(height: 24),

            _sectionTitle('Nonsuspect'),
            if (nonsuspect.isEmpty)
              _emptyHint('No nonsuspect devices yet')
            else
              ...nonsuspect.map((d) => _tile(context, d)),
          ],
        );
      },
    );
  }

  // Helper widget to display section titles for the Friendly, Unknown, and Suspect categories
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper widget to display a message when there are no devices in a specific category (Friendly, Unknown, or Suspect)
  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // Helper widget to build a ListTile for each detected device, displaying its name, last seen time, and estimated distance
  Widget _tile(BuildContext context, TrackerDevice d) {
    IconData icon;

    // Determine the appropriate icon to display based on the device's display name
    if (d.displayName.contains('AirTag')) {
      icon = Icons.apple;
    } else if (d.displayName.contains('Tile')) {
      icon = Icons.location_searching;
    } else if (d.displayName.contains('Samsung')) {
      icon = Icons.radio_button_checked;
    } else {
      icon = Icons.bluetooth;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => SearchPage(device: d)));
        },
        leading: Icon(icon),
        title: Text(
          d.displayName,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Last seen ${(DateTime.now().millisecondsSinceEpoch - d.lastSeenMs) ~/ 1000}s ago',
        ),
        trailing: Text(
          '${d.distance.toStringAsFixed(1)} m',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
