import 'package:flutter/material.dart';
import 'models.dart';
import 'device_marks.dart';
import 'search_page.dart';

// displays a list of detected tracker devices categorized as friendly, nonsuspect, suspect, or undesignated
class IdentificationPage extends StatelessWidget {
  final List<TrackerDevice> devices;
  final GlobalKey? classifyTabsKey;

  const IdentificationPage({
    required this.devices,
    this.classifyTabsKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: DeviceMarks.version,
      builder: (_, __, ___) {
        // De-dupe by signature (latest snapshot wins)
        final Map<String, TrackerDevice> unique = {};
        for (final d in devices) {
          unique[d.signature] = d;
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
  }) {
    return Column(
      children: [
        if (list.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Classifications'),
              onPressed: () {
                for (var d in list) {
                  DeviceMarks.clear(d.signature);
                }
              },
            ),
          ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    empty,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 14),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _deviceCard(context, list[i]),
                ),
        ),
      ],
    );
  }

  int _bars(int rssi) {
    if (rssi >= -55) return 5;
    if (rssi >= -65) return 4;
    if (rssi >= -75) return 3;
    if (rssi >= -85) return 2;
    return 1;
  }

  String _ageLabel(int lastSeenMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final s = ((now - lastSeenMs) / 1000).clamp(0, 999999).toInt();
    if (s < 60) return "${s}s ago";
    final m = (s ~/ 60);
    final rs = (s % 60);
    return "${m}m ${rs}s ago";
  }

  Widget _deviceCard(BuildContext context, TrackerDevice d) {
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
                    const SizedBox(height: 6),
                    Text(
                      'UUID: ${d.displayUuid}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'RSSI: ${d.rssi} dBm • Seen ${_ageLabel(d.lastSeenMs)}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'Distance: ${d.distanceFeet.toStringAsFixed(1)} ft',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.signal_cellular_alt,
                          size: 18,
                          color: i < _bars(d.smoothedRssi.round())
                              ? Colors.green
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
    );
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
      height: 60,
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
}

class _TabPill extends StatelessWidget {
  final String label;
  final Color color;

  const _TabPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_cellular_alt_rounded, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
