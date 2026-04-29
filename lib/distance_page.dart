import 'dart:async';
import 'package:flutter/material.dart';
import 'models.dart';
import 'search_page.dart';
import 'device_marks.dart';
import 'filters.dart';

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
  final Future<void> Function() onRefresh;

  const DistancePage({
    super.key,
    required this.devices,
    required this.scanning,
    required this.onRescan,
    required this.lastScanTime,
    required this.scanStartTime,
    required this.onRefresh,
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
    _tick = Timer.periodic(const Duration(milliseconds: 1000), (_) {
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

  String _scanElapsed() {
    final st = widget.scanStartTime;
    if (!widget.scanning || st == null) return "";
    final sec = ((_nowMs - st.millisecondsSinceEpoch) / 1000).floor().clamp(
      0,
      999999,
    );
    final mm = (sec ~/ 60).toString().padLeft(2, '0');
    final ss = (sec % 60).toString().padLeft(2, '0');
    return "$mm:$ss";
  }

  bool _isFresh(TrackerDevice d) {
    return (_nowMs - d.lastSeenMs) <= _freshPriorityWindowMs;
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
    final int elapsedSec = widget.scanStartTime != null
        ? ((_nowMs - widget.scanStartTime!.millisecondsSinceEpoch) / 1000).floor()
        : 0;
    
    // Check if we are currently inside the initial 10-second countdown phase
    final bool showCountdown = widget.scanning && elapsedSec < 10 && !widget.tutorialMode;

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
              // Filters the sorted devices list passed down from main.dart
              track = widget.devices
                  .where((d) => _showOnMainPage(d))
                  .where((d) => !DeviceMarks.isUndesignatedDismissed(d.stableKey))
                  .where((d) {
                    if (!s.filterByRssi) return true;
                    return d.smoothedRssi >= s.rssiThreshold;
                  })
                  .toList();
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
                    // Replaces empty states or lists with a massive countdown timer until 10 seconds completes
                    child: showCountdown
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(strokeWidth: 4, color: Colors.blueAccent),
                                const SizedBox(height: 32),
                                const Text(
                                  'Analyzing Area',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${10 - elapsedSec}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 72,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: widget.onRefresh,
                            child: track.isEmpty
                                ? ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      SizedBox(height: 100),
                                      Center(
                                        child: Text(
                                          'No trackers detected',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
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
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                padding: const EdgeInsets.all(4),
                                                child: buildTrackerImage(d, size: 60),
                                              ),
                                              const SizedBox(width: 20),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                      _isFresh(d) ? 'Active now' : 'Older reading',
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
                                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                ),
              ],
            );
          },
        );
      },
    );
  }
}
