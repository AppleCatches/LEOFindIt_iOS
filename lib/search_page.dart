// lib/search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher.dart';
import 'device_marks.dart';
import 'models.dart';
import 'ble_bridge.dart';
import 'reports_store.dart';
import 'app_tutorial.dart';

class SearchPage extends StatefulWidget {
  final TrackerDevice device;
  final bool tutorialMode;
  const SearchPage({
    required this.device,
    this.tutorialMode = false,
    super.key,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

enum ProximityBand { immediate, nearby, close, far, unknown }

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  TrackerDevice? live;
  StreamSubscription<TrackerDevice>? sub;
  Timer? _uiTimer;
  TrackerDevice? _pending;
  static const int _uiFrameMs = 60;
  double? _displayDistanceFt;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  Timer? _ageTick;
  int _nowMs = DateTime.now().millisecondsSinceEpoch;

  bool _manuallyFound = false;
  DateTime? _timeFound;

  final GlobalKey _distanceInfoKey = GlobalKey();
  final GlobalKey _signalStrengthKey = GlobalKey();
  final GlobalKey _categoryTabsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    live = widget.device;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_pulseCtrl);

    if (!widget.tutorialMode) {
      sub = BleBridge.detections.listen((d) {
        if (d.signature != widget.device.signature) return;
        _pending = d;
      });
      _uiTimer = Timer.periodic(const Duration(milliseconds: _uiFrameMs), (_) {
        if (!mounted || _pending == null) return;
        setState(() {
          _updateState(_pending!);
          live = _pending;
        });
      });
    } else {
      _displayDistanceFt = widget.device.distanceFeet;
      _updateState(widget.device);
    }

    _ageTick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() => _nowMs = DateTime.now().millisecondsSinceEpoch);
    });

    if (widget.tutorialMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        await _runTutorial();
      });
    }
  }

  // Smooth Android-style distance (kept exactly as before)
  void _updateState(TrackerDevice d) {
    final rawDist = d.distanceFeet;
    _displayDistanceFt ??= rawDist;

    final distanceDelta = rawDist - _displayDistanceFt!;
    const maxUiStepFt = 0.6;

    double clampedDistance = rawDist;
    if (distanceDelta.abs() > maxUiStepFt) {
      clampedDistance =
          _displayDistanceFt! +
          (distanceDelta.isNegative ? -maxUiStepFt : maxUiStepFt);
    }

    _displayDistanceFt =
        (_displayDistanceFt! * 0.96) + (clampedDistance * 0.04);
  }

  Future<bool> _showCoach(List<TargetFocus> targets) async {
    if (!mounted || targets.isEmpty) return false;
    final completer = Completer<bool>();
    final coach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.78,
      paddingFocus: 10,
      hideSkip: true,
      onFinish: () {
        if (!completer.isCompleted) completer.complete(true);
      },
      onSkip: () {
        if (!completer.isCompleted) completer.complete(false);
        return true; // ← REQUIRED by the library
      },
    );
    await Future.delayed(const Duration(milliseconds: 100));
    coach.show(context: context);
    return completer.future;
  }

  Future<void> _runTutorial() async {
    await _showCoach([
      tutorialTarget(
        key: _distanceInfoKey,
        id: 'search_distance',
        title: 'Distance and signal',
        body: 'Tracker distance and signal strengths are displayed here.',
        showSkip: false,
      ),
      tutorialTarget(
        key: _signalStrengthKey,
        id: 'search_signal_colors',
        title: 'Signal strength colors',
        body:
            'Grey, yellow, and green show strength from weakest to strongest.',
        showSkip: false,
      ),
      tutorialTarget(
        key: _categoryTabsKey,
        id: 'search_categories',
        title: 'Tracker categories',
        body:
            'You can put a tracker in three categories: Friendly, Undesignated, and Suspect.',
        align: ContentAlign.top,
        showSkip: false,
      ),
    ]);
    if (mounted) Navigator.pop(context);
  }

  String _ageLabel(int lastSeenMs) {
    final s = ((_nowMs - lastSeenMs) / 1000).clamp(0, 999999).toInt();
    if (s < 60) return "${s}s ago";
    final m = (s ~/ 60);
    final rs = (s % 60);
    return "${m}m ${rs}s ago";
  }

  ProximityBand _bandFromRssi(double rssi) {
    if (rssi >= -55) return ProximityBand.immediate;
    if (rssi >= -65) return ProximityBand.nearby;
    if (rssi >= -75) return ProximityBand.close;
    if (rssi >= -85) return ProximityBand.far;
    return ProximityBand.unknown;
  }

  Color _bandColor(ProximityBand band) {
    switch (band) {
      case ProximityBand.immediate:
        return const Color(0xFF2E7D32);
      case ProximityBand.nearby:
        return const Color(0xFF66BB6A);
      case ProximityBand.close:
        return const Color(0xFFF9A825);
      case ProximityBand.far:
        return const Color(0xFFEF6C00);
      case ProximityBand.unknown:
        return Colors.grey.shade500;
    }
  }

  String _bandLabel(ProximityBand band) {
    switch (band) {
      case ProximityBand.immediate:
        return 'Very Close';
      case ProximityBand.nearby:
        return 'Nearby';
      case ProximityBand.close:
        return 'Close';
      case ProximityBand.far:
        return 'Far';
      case ProximityBand.unknown:
        return 'Unknown';
    }
  }

  void _markFound(TrackerDevice d) async {
    await BleBridge.stopScan();
    setState(() {
      _manuallyFound = true;
      _timeFound = DateTime.now();
    });
    _pulseCtrl.repeat(reverse: true);
  }

  void _submitReport(TrackerDevice d) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspect Tag Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'I opt in to SMS with LeoFindIt developers only regarding the matter in my feedback. I can send STOP anytime to opt out.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Classified Suspect: ${DateTime.now().toString().split('.')[0]}',
              ),
              Text(
                'UUID: ...${d.shortUuid}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'First Scanned: ${DateTime.fromMillisecondsSinceEpoch(d.firstSeenMs).toString().split('.')[0]}',
              ),
              Text(
                'Last Scanned: ${DateTime.fromMillisecondsSinceEpoch(d.lastSeenMs).toString().split('.')[0]}',
              ),
              Text(
                'Marked Found: ${_timeFound?.toString().split('.')[0] ?? "N/A"}',
              ),
              Text('Last Distance: ${d.distanceFeet.toStringAsFixed(1)} ft'),
              const SizedBox(height: 12),
              const Text(
                'Suggest: Screen shot this report, photograph the tag where found, and zoom in to photograph the tag serial number.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please include a sentence stating the crime and resolution and any app feedback below:',
              ),
              const SizedBox(height: 6),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Crime, resolution, feedback...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final body =
                  "LeoFindIt Suspect Report:\nUUID: ...${d.shortUuid}\nFirst Scanned: ${DateTime.fromMillisecondsSinceEpoch(d.firstSeenMs)}\nLast Scanned: ${DateTime.fromMillisecondsSinceEpoch(d.lastSeenMs)}\nFound: $_timeFound\nLast Distance: ${d.distanceFeet.toStringAsFixed(1)} ft\n\nNotes: ${ctrl.text}";
              final uri = Uri.parse(
                "mailto:feedback@leofindit.com?subject=LeoFindIt Suspect Report&body=${Uri.encodeComponent(body)}",
              );
              try {
                await launchUrl(uri);
              } catch (_) {}
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Email'),
          ),
          ElevatedButton(
            onPressed: () async {
              final body =
                  "LeoFindIt Suspect Report:\nUUID: ...${d.shortUuid}\nFirst Scanned: ${DateTime.fromMillisecondsSinceEpoch(d.firstSeenMs)}\nLast Scanned: ${DateTime.fromMillisecondsSinceEpoch(d.lastSeenMs)}\nFound: $_timeFound\nLast Distance: ${d.distanceFeet.toStringAsFixed(1)} ft\n\nNotes: ${ctrl.text}";
              final uri = Uri.parse(
                "sms:9383686348?body=${Uri.encodeComponent(body)}",
              );
              try {
                await launchUrl(uri);
              } catch (_) {}
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('SMS'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    sub?.cancel();
    _uiTimer?.cancel();
    _ageTick?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = live ?? widget.device;
    final band = _bandFromRssi(d.smoothedRssi);
    final color = _bandColor(band);
    final DeviceMark? mark = DeviceMarks.getMark(d.signature);

    final Color circleColor = _manuallyFound ? const Color(0xFF2E7D32) : color;
    final IconData centerIcon = _manuallyFound
        ? Icons.check_rounded
        : Icons.navigation_rounded;

    return Scaffold(
      appBar: AppBar(
        title: Text(d.displayName, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_manuallyFound) ...[
                const SizedBox(height: 30),

                // ANDROID-STYLE LARGE COLORED CIRCLE ICON (exactly what Android uses)
                ScaleTransition(
                  scale: _pulseCtrl.value > 1.0
                      ? _pulseAnim
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleColor,
                    ),
                    child: Icon(centerIcon, size: 90, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 22),
                Text(
                  _bandLabel(band),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),
                TutorialBlinker(
                  isTutorialMode: widget.tutorialMode,
                  child: Column(
                    key: _distanceInfoKey,
                    children: [
                      Text(
                        "RSSI: ${d.rssi} dBm",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Distance: ${(_displayDistanceFt ?? d.distanceFeet).toStringAsFixed(1)} ft',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Seen ${_ageLabel(d.lastSeenMs)}",
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                TutorialBlinker(
                  isTutorialMode: widget.tutorialMode,
                  child: Container(
                    key: _signalStrengthKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: color, width: 2.5),
                    ),
                    child: Text(
                      _bandLabel(band),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle, size: 28),
                  label: const Text('Found', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () => _markFound(d),
                ),
              ] else ...[
                const Text(
                  'DEVICE FOUND',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'UUID: ...${d.shortUuid}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Date/Time: ${_timeFound?.toString().split('.')[0] ?? "N/A"}',
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.report),
                  label: const Text('Create Report'),
                  onPressed: () => _submitReport(d),
                ),
              ],

              const SizedBox(height: 30),
              TutorialBlinker(
                isTutorialMode: widget.tutorialMode,
                child: Padding(
                  key: _categoryTabsKey,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _MarkTabs(
                    selected: mark,
                    onSelect: (m) {
                      final DeviceMark? newMark = (m == mark) ? null : m;
                      setState(() => DeviceMarks.setMark(d.signature, newMark));
                      if (newMark == DeviceMark.suspect &&
                          !widget.tutorialMode) {
                        ReportsStore.createFromDevice(d);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'UUID: ...${d.shortUuid}',
                style: const TextStyle(fontFamily: 'Inter'),
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
  final ValueChanged<DeviceMark> onSelect;
  const _MarkTabs({required this.selected, required this.onSelect});

  static const Color _friendly = Color(0xFF2E7D32);
  static const Color _suspect = Color(0xFFD9534F);
  static const Color _undesignated = Color(0xFF1500FF);

  @override
  Widget build(BuildContext context) {
    final bg = Colors.grey.shade100;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Pill(
              label: 'Suspect',
              color: _suspect,
              selected: selected == DeviceMark.suspect,
              onTap: () => onSelect(DeviceMark.suspect),
            ),
          ),
          Expanded(
            child: _Pill(
              label: 'Friendly',
              color: _friendly,
              selected: selected == DeviceMark.friendly,
              onTap: () => onSelect(DeviceMark.friendly),
            ),
          ),
          Expanded(
            child: _Pill(
              label: 'Undesig.',
              color: _undesignated,
              selected: selected == DeviceMark.undesignated,
              onTap: () => onSelect(DeviceMark.undesignated),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? Colors.grey.shade300 : Colors.transparent,
          width: 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                  color: Colors.black.withOpacity(0.06),
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.signal_cellular_alt_rounded, size: 14, color: color),
              const SizedBox(width: 2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      fontSize: 12,
                      color: selected ? Colors.black : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
