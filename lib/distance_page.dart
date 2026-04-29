import 'dart:async';
import 'package:flutter/material.dart';
import 'models.dart';
import 'search_page.dart';
import 'device_marks.dart';
import 'filters.dart';

// In the app this is labeled the Scan page, it is the first page the app opens to...

class DistancePage extends StatefulWidget {
  final List<TrackerDevice> devices;
  final bool scanning;
  final VoidCallback onRescan;
  final DateTime? lastScanTime;
  final DateTime? scanStartTime;

  final GlobalKey? scanButtonKey;
  final GlobalKey? trackerListKey;
  final GlobalKey? firstTrackerCardKey;

  final bool tutorialMode;
  final TrackerDevice? tutorialDevice;

  const DistancePage({
    super.key,
    required this.devices,
    required this.scanning,
    required this.onRescan,
    required this.lastScanTime,
    required this.scanStartTime,
    this.scanButtonKey,
    this.trackerListKey,
    this.firstTrackerCardKey,
    this.tutorialMode = false,
    this.tutorialDevice,
  });

  @override
  State<DistancePage> createState() => _DistancePageState();
}

class _DistancePageState extends State<DistancePage> {
  static const int _freshPriorityWindowMs = 15 * 1000;

  Timer? _tick;
  int _nowMs = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (!mounted) return;
      setState(() => _nowMs = DateTime.now().millisecondsSinceEpoch);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    int hour = t.hour % 12;
    if (hour == 0) hour = 12;
    final min = t.minute.toString().padLeft(2, '0');
    final am = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $am';
  }

  String _ageLabel(int lastSeenMs) {
    final s = ((_nowMs - lastSeenMs) / 1000).clamp(0, 999999).toDouble();
    if (s < 60) return "${s.toStringAsFixed(1)}s ago";
    final m = (s / 60).floor();
    final rs = (s - m * 60).floor();
    return "${m}m ${rs}s ago";
  }

  String _scanElapsed() {
    final st = widget.scanStartTime;
    if (!widget.scanning || st == null) return "";
    final sec =
    ((_nowMs - st.millisecondsSinceEpoch) / 1000).floor().clamp(0, 999999);
    final mm = (sec ~/ 60).toString().padLeft(2, '0');
    final ss = (sec % 60).toString().padLeft(2, '0');
    return "$mm:$ss";
  }

  String _assetForDevice(TrackerDevice d) {
    if (d.isLikelyAirTag) return 'assets/airtag.png';
    if (d.isLikelyTile) return 'assets/tile.png';
    if (d.isLikelyFindMy) return 'assets/findmy.png';
    if (d.isLikelySamsung) return 'assets/smarttag2.png';
    return 'assets/leo_splash.png';
  }

  bool _isFresh(TrackerDevice d) {
    return (_nowMs - d.lastSeenMs) <= _freshPriorityWindowMs;
  }

  List<TrackerDevice> _sortedForDistancePage(
      List<TrackerDevice> input,
      FiltersState filters,
      ) {
    final list = [...input];

    if (filters.sortMode == SortMode.distanceAsc) {
      list.sort((a, b) {
        final aFresh = _isFresh(a);
        final bFresh = _isFresh(b);

        if (aFresh != bFresh) return aFresh ? -1 : 1;

        final recentGap = (a.lastSeenMs - b.lastSeenMs).abs();
        if (recentGap > 5000) {
          return b.lastSeenMs.compareTo(a.lastSeenMs);
        }

        final c = a.distanceUiM.compareTo(b.distanceUiM);
        if (c != 0) return c;

        return b.lastSeenMs.compareTo(a.lastSeenMs);
      });
      return list;
    }

    list.sort((a, b) {
      final aFresh = _isFresh(a);
      final bFresh = _isFresh(b);

      if (aFresh != bFresh) return aFresh ? -1 : 1;

      final recentGap = (a.lastSeenMs - b.lastSeenMs).abs();
      if (recentGap > 5000) {
        return b.lastSeenMs.compareTo(a.lastSeenMs);
      }

      final c = b.smoothedRssi.compareTo(a.smoothedRssi);
      if (c != 0) return c;

      return b.lastSeenMs.compareTo(a.lastSeenMs);
    });

    return list;
  }

  Future<void> _dismissUndesignated(TrackerDevice d) async {
    await DeviceMarks.dismissUndesignated(d.stableKey);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${d.displayName} removed from undesignated list',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              DeviceMarks.restoreUndesignated(d.stableKey);
            },
          ),
        ),
      );
  }

  bool _showOnMainPage(TrackerDevice d) {
    final mark = DeviceMarks.get(d.stableKey);
    return mark == DeviceMark.undesignated || mark == DeviceMark.suspect;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: DeviceMarks.version,
      builder: (_, __, ___) {
        return ValueListenableBuilder<FiltersState>(
          valueListenable: FiltersModel.notifier,
          builder: (_, s, ____) {
            final List<TrackerDevice> track;

            if (widget.tutorialMode && widget.tutorialDevice != null) {
              track = [widget.tutorialDevice!];
            } else {
              track = _sortedForDistancePage(
                widget.devices
                    .where((d) =>
                d.isLikelyAirTag ||
                    d.isLikelyTile ||
                    d.isLikelyFindMy ||
                    d.isLikelySamsung)
                    .where((d) => _showOnMainPage(d))
                    .where((d) =>
                !DeviceMarks.isUndesignatedDismissed(d.stableKey))
                    .where((d) {
                  if (!s.filterByRssi) return true;
                  return d.smoothedRssi >= s.rssiThreshold;
                }).toList(),
                s,
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        key: widget.scanButtonKey,
                        icon: Icon(
                          widget.scanning
                              ? Icons.stop_circle_rounded
                              : Icons.play_circle_fill_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                        label: Text(
                          widget.scanning ? 'Stop Scan' : 'Start Scan',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.scanning
                              ? const Color(0xFF58A1F1).withOpacity(0.95)
                              : const Color(0xFF57A8F1).withOpacity(0.95),
                          elevation: 2,
                          shadowColor: Colors.black26,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35),
                          ),
                        ).copyWith(
                          overlayColor: WidgetStatePropertyAll(
                            Colors.white.withOpacity(0.20),
                          ),
                        ),
                        onPressed: widget.onRescan,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.tutorialMode
                            ? 'Tutorial demo tracker'
                            : widget.scanning
                            ? 'Scanning…  ${_scanElapsed()}'
                            : widget.lastScanTime == null
                            ? 'No scans yet'
                            : 'Last scan ${_formatTime(widget.lastScanTime)}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    key: widget.trackerListKey,
                    child: track.isEmpty
                        ? const Center(
                      child: Text(
                        'No undesignated or suspect tags detected',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    )
                        : ListView.builder(
                      itemCount: track.length,
                      itemBuilder: (_, i) {
                        final d = track[i];
                        final mark = DeviceMarks.get(d.stableKey);

                        final card = Card(
                          key: i == 0 ? widget.firstTrackerCardKey : null,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius:
                                    BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Image.asset(
                                    _assetForDevice(d),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.displayName,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'UUID: …${d.shortUuid}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      /*
                                      Text(
                                        'MAC last 4: ${d.macTail4}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      */
                                      if (mark == DeviceMark.suspect) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Marked suspect',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                      if (d.mayBeRotatingDuplicate)
                                        Text(
                                          'Possible duplicate from rotating IDs',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Distance: ${d.distanceFt.toStringAsFixed(1)} ft',
                                      ),
                                      Text(
                                        'RSSI: ${d.rssi} dBm • Seen ${_ageLabel(d.lastSeenMs)}',
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _isFresh(d)
                                            ? 'Active now'
                                            : 'Older reading',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          color: _isFresh(d)
                                              ? const Color(0xFF2E7D32)
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (widget.tutorialMode) {
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SearchPage(
                                  device: d,
                                  tutorialMode: widget.tutorialMode,
                                ),
                              ),
                            ),
                            child: card,
                          );
                        }

                        return Dismissible(
                          key: ValueKey('undesignated_${d.stableKey}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.hide_source_rounded,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Hide',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (_) => _dismissUndesignated(d),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SearchPage(
                                  device: d,
                                  tutorialMode: widget.tutorialMode,
                                ),
                              ),
                            ),
                            child: card,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
