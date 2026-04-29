import 'package:flutter/material.dart';
import 'models.dart';
import 'device_marks.dart';
import 'search_page.dart';

class IdentificationPage extends StatefulWidget {
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

        final allKnown = unique.values.toList()
          ..sort((a, b) => b.lastSeenMs.compareTo(a.lastSeenMs));

        final liveUndesignated = allKnown.where((d) {
          if (DeviceMarks.get(d.stableKey) != DeviceMark.undesignated) {
            return false;
          }
          if (d.distance <= 0) return false;
          if (nowMs - d.lastSeenMs > _activeWindowMs) return false;
          return true;
        }).toList();

        final friendly = allKnown
            .where((d) => DeviceMarks.get(d.stableKey) == DeviceMark.friendly)
            .toList();

        final nonsuspect = allKnown
            .where((d) => DeviceMarks.get(d.stableKey) == DeviceMark.nonsuspect)
            .toList();

        final suspect = allKnown
            .where((d) => DeviceMarks.get(d.stableKey) == DeviceMark.suspect)
            .toList();

        List<TrackerDevice> visible;
        String emptyText;

        if (_selectedFilter == null) {
          visible = liveUndesignated;
          emptyText = 'No undesignated tags yet';
        } else if (_selectedFilter == DeviceMark.friendly) {
          visible = friendly;
          emptyText = 'No friendly tags yet';
        } else if (_selectedFilter == DeviceMark.nonsuspect) {
          visible = nonsuspect;
          emptyText = 'No nonsuspect tags yet';
        } else if (_selectedFilter == DeviceMark.suspect) {
          visible = suspect;
          emptyText = 'No suspect tags yet';
        } else {
          visible = liveUndesignated;
          emptyText = 'No undesignated tags yet';
        }

        return Column(
          children: [
            Padding(
              key: widget.identifyTabsKey,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: _MarkTabs(
                selected: _selectedFilter,
                onTap: (mark) {
                  setState(() {
                    if (_selectedFilter == mark) {
                      _selectedFilter = null;
                    } else {
                      _selectedFilter = mark;
                    }
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Center(
                child: Text(
                  _selectedFilter == null
                      ? 'Showing live undesignated tags'
                      : 'Showing ${_selectedFilter!.label.toLowerCase()} tags',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _list(
                context,
                visible,
                empty: emptyText,
                nowMs: nowMs,
              ),
            ),
          ],
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
    final s = ((now - lastSeenMs) / 1000).clamp(0, 999999).toDouble();
    if (s < 60) return "${s.toStringAsFixed(1)}s ago";
    final m = (s / 60).floor();
    final rs = (s - m * 60).floor();
    return "${m}m ${rs}s ago";
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  _assetForDevice(d),
                  fit: BoxFit.contain,
                ),
              ),
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
                    // Text('MAC last 4: ${d.macTail4}'),
                    const SizedBox(height: 6),
                    Text(
                      'Distance: ${d.distanceFt.toStringAsFixed(1)} ft',
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
}

class _MarkTabs extends StatelessWidget {
  final DeviceMark? selected;
  final ValueChanged<DeviceMark> onTap;

  const _MarkTabs({
    required this.selected,
    required this.onTap,
  });

  static const _friendly = Color(0xFF2E7D32);
  static const _suspect = Color(0xFFD9534F);
  static const _undesignated = Color(0xFF7A7A7A);
  static const _nonsuspect = Color(0xFF1E88E5);

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
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _pill(
            label: 'Friendly',
            color: _friendly,
            mark: DeviceMark.friendly,
          ),
          _pill(
            label: 'Nonsuspect',
            color: _nonsuspect,
            mark: DeviceMark.nonsuspect,
          ),
          _pill(
            label: 'Suspect',
            color: _suspect,
            mark: DeviceMark.suspect,
          ),
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
