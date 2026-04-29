// lib/identification_page.dart

import 'package:flutter/material.dart';
import 'models.dart';
import 'device_marks.dart';
import 'search_page.dart';

// displays a list of detected tracker devices categorized as friendly, nonsuspect, suspect, or undesignated
class IdentificationPage extends StatelessWidget {
  final List<TrackerDevice> devices;
  final GlobalKey? identifyTabsKey;

  const IdentificationPage({
    required this.devices,
    this.identifyTabsKey,
    super.key,
  });

  @override
  State<IdentificationPage> createState() => _IdentificationPageState();
}

class _IdentificationPageState extends State<IdentificationPage> {
  DeviceMark? _selectedFilter;

  static const int _activeWindowMs = 30 * 1000;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: DeviceMarks.version,
      builder: (_, __, ___) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        final Map<String, TrackerDevice> unique = {};
        for (final d in widget.devices) {
          final key = d.stableKey;
          final prev = unique[key];

          if (prev == null || d.lastSeenMs > prev.lastSeenMs) {
            unique[key] = d;
          }
        }

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final qualified = unique.values.where((d) {
          if (d.distanceFeet <= 0) return false;
          if (nowMs - d.lastSeenMs > 30 * 1000) return false;
          return true;
        }).toList();

        final suspect = <TrackerDevice>[];
        final friendly = <TrackerDevice>[];
        final nonsuspect = <TrackerDevice>[];
        final undesignated = <TrackerDevice>[];

        for (final d in qualified) {
          final mark = DeviceMarks.getMark(d.signature);
          if (mark == DeviceMark.suspect) {
            suspect.add(d);
          } else if (mark == DeviceMark.friendly) {
            friendly.add(d);
          } else if (mark == DeviceMark.nonsuspect) {
            nonsuspect.add(d);
          } else {
            undesignated.add(d); // default = undesignated
          }
        }

        return DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Padding(
                key: classifyTabsKey,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: const _MarkTabs(),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _list(context, suspect, empty: 'No suspect trackers yet'),
                    _list(context, friendly, empty: 'No friendly trackers yet'),
                    _list(
                      context,
                      nonsuspect,
                      empty: 'No nonsuspect trackers yet',
                    ),
                    _list(
                      context,
                      undesignated,
                      empty: 'No undesignated trackers yet',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _list(
    BuildContext context,
    List<TrackerDevice> list, {
    required String empty,
    required int nowMs,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          empty,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 14),
      itemCount: list.length,
      itemBuilder: (_, i) => _deviceCard(context, list[i], nowMs: nowMs),
    );
  }

  String _ageLabel(int lastSeenMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffSec = ((now - lastSeenMs) / 1000).floor();

    if (diffSec < 60) return "${diffSec}s ago";

    final m = (diffSec ~/ 60);
    final s = (diffSec % 60);

    if (m < 60) return "${m}m ${s}s ago";

    final h = (m ~/ 60);
    final remM = (m % 60);
    return "${h}hr ${remM}m ago";
  }

  bool _isStale(int lastSeenMs, int nowMs) {
    return nowMs - lastSeenMs > _activeWindowMs;
  }

  String _assetForDevice(TrackerDevice d) {
    if (d.isLikelyAirTag) return 'assets/airtag.png';
    if (d.isLikelyTile) return 'assets/tile.png';
    if (d.isLikelyFindMy) return 'assets/findmy.png';
    if (d.isLikelySamsung) return 'assets/smarttag2.png';
    return 'assets/leo_splash.png';
  }

  Widget _deviceCard(
    BuildContext context,
    TrackerDevice d, {
    required int nowMs,
  }) {
    final stale = _isStale(d.lastSeenMs, nowMs);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SearchPage(device: d)),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              buildTrackerImage(
                d,
                size: 44,
              ), // assuming this is defined elsewhere
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.displayName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('UUID: …${d.shortUuid}'),
                    Text('MAC last 4: ${d.macTail4}'),
                    const SizedBox(height: 6),
                    Text(
                      'UUID: ${d.displayUuid}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'RSSI: ${d.rssi} dBm • Seen ${_ageLabel(d.lastSeenMs)}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (stale) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Stale tag • not currently active',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _markColor(DeviceMark? mark) {
    switch (mark ?? DeviceMark.undesignated) {
      case DeviceMark.suspect:
        return const Color(0xFFD9534F);
      case DeviceMark.friendly:
        return const Color(0xFF2E7D32);
      case DeviceMark.undesignated:
        return const Color(0xFF1500FF);
    }
  }
}

class _MarkTabs extends StatelessWidget {
  const _MarkTabs();

  static const _suspect = Color(0xFFD9534F);
  static const _friendly = Color(0xFF2E7D32);
  static const _nonsuspect = Color(0xFF17A2B8);
  static const _undesignated = Color(0xFF1500FF);

  @override
  Widget build(BuildContext context) {
    final bg = Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 3),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        labelPadding: EdgeInsets.zero,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey.shade700,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          _TabPill(label: 'Suspect', color: _suspect),
          _TabPill(label: 'Friendly', color: _friendly),
          // _TabPill(label: 'Nonsuspect', color: _nonsuspect),
          _TabPill(label: 'Undesignated', color: _undesignated),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required Color color,
    required DeviceMark mark,
  }) {
    final active = selected == mark;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onTap(mark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? color : const Color(0xFFB0B0B0),
            width: active ? 2 : 1.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                color: active ? Colors.black : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Using google icons for icons here:
// https://fonts.google.com/icons?selected=Material+Symbols+Outlined:stacks:FILL@0;wght@400;GRAD@0;opsz@24&icon.size=24&icon.color=%23e3e3e3
