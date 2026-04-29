import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'device_marks.dart';
import 'models.dart';
import 'ble_bridge.dart';
import 'reports_store.dart';
import 'app_tutorial.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

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
  static const int _uiFrameMs = 80;

  double? _displayDistanceM;
  double? _displayRssi;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  Timer? _ageTick;
  int _nowMs = DateTime.now().millisecondsSinceEpoch;

  bool _manuallyFound = false;
  TrackerReport? _foundReport;

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

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_pulseCtrl);

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
      _displayDistanceM = widget.device.distanceUiM;
      _displayRssi = widget.device.smoothedRssi;
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
        return true;
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
        showClose: true,
      ),
      tutorialTarget(
        key: _signalStrengthKey,
        id: 'search_signal_colors',
        title: 'Signal strength colors',
        body: 'Grey, yellow, and green show strength from weakest to strongest.',
        showClose: true,
      ),
      tutorialTarget(
        key: _categoryTabsKey,
        id: 'search_categories',
        title: 'Tracker categories',
        body:
        'You can put a tracker in four categories: Undesignated, Friendly, Nonsuspect, and Suspect.',
        align: ContentAlign.top,
        showClose: true,
        isLastStep: true,
      ),
    ]);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _feetLabel(double meters) {
    final feet = meters * 3.28084;
    return '${feet.toStringAsFixed(feet < 10 ? 1 : 0)} ft';
  }

  String _ageLabel(int lastSeenMs) {
    final s = ((_nowMs - lastSeenMs) / 1000).clamp(0, 999999).toDouble();
    if (s < 60) return "${s.toInt()}s ago";
    final m = (s / 60).floor();
    final rs = (s - m * 60).floor();
    return "${m}m ${rs}s ago";
  }

  String _assetForDevice(TrackerDevice d) {
    if (d.isLikelyAirTag || d.isPossibleAirTag) return 'assets/airtag.png';
    if (d.isLikelyFindMy) return 'assets/applefindmy.png';
    if (d.isLikelyTile) return 'assets/tile.png';
    if (d.isLikelySamsung) return 'assets/smarttag.png';
    return 'assets/unknown.png';
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
        return Colors.grey.shade500;
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

  void _updateState(TrackerDevice d) {
    final rawDist = d.distanceUiM;
    final rawRssi = d.smoothedRssi;

    _displayDistanceM ??= rawDist;
    _displayRssi ??= rawRssi;

    final distanceDelta = rawDist - _displayDistanceM!;
    const maxUiStepM = 0.18;

    double clampedDistance = rawDist;
    if (distanceDelta.abs() > maxUiStepM) {
      clampedDistance =
          _displayDistanceM! + (distanceDelta.isNegative ? -maxUiStepM : maxUiStepM);
    }

    _displayDistanceM = (_displayDistanceM! * 0.96) + (clampedDistance * 0.04);
    _displayRssi = (_displayRssi! * 0.90) + (rawRssi * 0.10);
  }

  Future<void> _setMark(TrackerDevice d, DeviceMark mark) async {
    await DeviceMarks.set(d.stableKey, mark);

    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${d.displayName} marked ${mark.label.toLowerCase()}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _markFound() async {
    setState(() {
      _manuallyFound = true;
    });

    _pulseCtrl.repeat(reverse: true);
    HapticFeedback.mediumImpact();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tag marked as found. Scan remains live.'),
      ),
    );
  }

  Future<void> _createReport() async {
    if (widget.tutorialMode) return;

    final d = live ?? widget.device;

    if (_foundReport != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Report already created for this tag in this session.'),
          ),
        );
      return;
    }

    final report = await ReportsStore.createFromDevice(d);
    _foundReport = report;

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Report created for ${d.displayName}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> _launchEmail() async {
    final d = live ?? widget.device;
    final body = '''
LeoFindIt feedback

Tag type: ${d.displayName}
UUID tail: ${d.shortUuid}
Observed at: ${DateTime.now()}

Please enter your feedback here.
''';

    final uri = Uri(
      scheme: 'mailto',
      path: 'leofindit@icloud.com',
      queryParameters: {
        'subject': 'LeoFindIt Report Feedback',
        'body': body,
      },
    );

    await launchUrl(uri);
  }

  Future<void> _launchSms() async {
    final d = live ?? widget.device;
    final body =
        'LeoFindIt feedback\nType: ${d.displayName}\nUUID tail: ${d.shortUuid}\n';
    final uri = Uri.parse('sms:8015281285?body=${Uri.encodeComponent(body)}');
    await launchUrl(uri);
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
    final band = _bandFromRssi(_displayRssi ?? d.smoothedRssi);
    final color = _bandColor(band);
    final mark = DeviceMarks.get(d.stableKey);

    final Color centerCircleColor =
    _manuallyFound ? const Color(0xFF2E7D32) : color;

    final IconData centerIcon =
    _manuallyFound ? Icons.check_rounded : Icons.navigation_rounded;

    final String statusText =
    _manuallyFound ? 'Tag located' : _bandLabel(band);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 160, // Main Scan
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            label: const Text(
              'Main Scan',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
        title: Text(
          d.displayName,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 18),
              ScaleTransition(
                scale: _manuallyFound
                    ? _pulseAnim
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: centerCircleColor,
                  ),
                  child: Icon(centerIcon, size: 90, color: Colors.white),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                statusText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                key: _distanceInfoKey,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _feetLabel(_displayDistanceM ?? d.distanceUiM),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "RSSI: ${(_displayRssi ?? d.smoothedRssi).toStringAsFixed(1)} dBm • Seen ${_ageLabel(d.lastSeenMs)}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "UUID: …${d.shortUuid}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                key: _signalStrengthKey,
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(
                  _bandLabel(band),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _markFound,
                  icon: Icon(
                    _manuallyFound
                        ? Icons.check_rounded
                        : Icons.check_circle_outline_rounded,
                  ),
                  label: Text(_manuallyFound ? 'Found' : 'Found it?'),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1.6,
                  ),
                  color: Colors.grey.shade50,
                ),
                child: Padding(
                  key: _categoryTabsKey,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: _MarkTabs(
                    selected: mark,
                    onSelect: (m) => _setMark(d, m),
                  ),
                ),
              ),
              if (_manuallyFound) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _createReport,
                    icon: Icon(
                      _foundReport == null
                          ? Icons.description_outlined
                          : Icons.check_circle_outline_rounded,
                    ),
                    label: Text(
                      _foundReport == null
                          ? 'Create report'
                          : 'Report created',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _launchEmail,
                        icon: const Icon(Icons.email_outlined),
                        label: const Text('Email'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _launchSms,
                        icon: const Icon(Icons.sms_outlined),
                        label: const Text('SMS'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit feedback to the student developers.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkTabs extends StatelessWidget {
  final DeviceMark selected;
  final ValueChanged<DeviceMark> onSelect;

  const _MarkTabs({required this.selected, required this.onSelect});

  static const Color _friendly = Color(0xFF2E7D32);
  static const Color _suspect = Color(0xFFD9534F);
  static const Color _undesignated = Color(0xFF7A7A7A);
  static const Color _nonsuspect = Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    final bg = Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _Pill(
            label: 'Undesignated',
            color: _undesignated,
            selected: selected == DeviceMark.undesignated,
            onTap: () => onSelect(DeviceMark.undesignated),
          ),
          _Pill(
            label: 'Friendly',
            color: _friendly,
            selected: selected == DeviceMark.friendly,
            onTap: () => onSelect(DeviceMark.friendly),
          ),
          _Pill(
            label: 'Nonsuspect',
            color: _nonsuspect,
            selected: selected == DeviceMark.nonsuspect,
            onTap: () => onSelect(DeviceMark.nonsuspect),
          ),
          _Pill(
            label: 'Suspect',
            color: _suspect,
            selected: selected == DeviceMark.suspect,
            onTap: () => onSelect(DeviceMark.suspect),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.signal_cellular_alt_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 14,
                  color: selected ? Colors.black : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
