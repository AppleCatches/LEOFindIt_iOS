import 'package:flutter/material.dart';

import 'filters.dart';

class FiltersPage extends StatelessWidget {
  const FiltersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FiltersState>(
      valueListenable: FiltersModel.notifier,
      builder: (_, s, __) {
        final missionLabel = s.missionMode == MissionMode.packageSearch
            ? 'Package mission'
            : 'Known-area tag hunt';

        return Scaffold(
          appBar: AppBar(title: const Text('Filters')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _SectionTitle('Package mission / search mission'),
              _ActionCard(
                title: 'Sealed package search',
                subtitle:
                'I\'m determining if there is a tag inside of a sealed package. Metal safe, cardboard, plastic, or another confined item.',
                onTap: () {
                  FiltersModel.applyMissionPreset(MissionMode.packageSearch);
                },
              ),
              const SizedBox(height: 10),
              _ActionCard(
                title: 'Known-area tag hunt',
                subtitle:
                'I\'m hunting for a possible tag in a known area such as a vehicle or backpack.',
                onTap: () {
                  FiltersModel.applyMissionPreset(MissionMode.wideAreaHiddenTag);
                },
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                color: const Color(0xFFF8F7FA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Current mission: $missionLabel',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionTitle('Permissions / privacy'),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Your phone may ask for Bluetooth permissions when you scan. LeoFindIt asks for Bluetooth Scan, Bluetooth Connect, and on older Android versions location permission for BLE scanning. Some Android devices also require Location Services to be turned on for BLE scanning to work.\n\nLeoFindIt collects ZERO information unless you choose to send feedback after reporting a tag.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionTitle('Filter'),
              _ToggleCard(
                title: 'Filter by RSSI',
                subtitle:
                'Show only devices with RSSI stronger than your threshold.',
                value: s.filterByRssi,
                onChanged: FiltersModel.setFilterByRssi,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: s.filterByRssi
                      ? _RssiSlider(
                    value: s.rssiThreshold,
                    onChanged: FiltersModel.setRssiThreshold,
                  )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionTitle('Sorting'),
              _ToggleCard(
                title: 'Strongest signal',
                subtitle:
                'Keeps the strongest recent signal near the top without constant jumping.',
                value: s.sortMode == SortMode.strongestHold,
                onChanged: (v) {
                  if (v) FiltersModel.setSortMode(SortMode.strongestHold);
                },
              ),
              const SizedBox(height: 10),
              _ToggleCard(
                title: 'By distance',
                subtitle: 'Closest to farthest using distance estimates.',
                value: s.sortMode == SortMode.distanceAsc,
                onChanged: (v) {
                  if (v) FiltersModel.setSortMode(SortMode.distanceAsc);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? child;

  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: 10),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _RssiSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RssiSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Threshold: $value dBm',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Slider(
          min: -100,
          max: -40,
          divisions: 60,
          value: value.toDouble(),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
