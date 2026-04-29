import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'ble_bridge.dart';
import 'models.dart';
import 'distance_page.dart';
import 'identification_page.dart';
import 'device_marks.dart';
import 'app_drawer.dart';
import 'filters.dart';
import 'reports_store.dart';
import 'search_page.dart';
import 'app_tutorial.dart';
import 'advanced_scanner_view.dart';

void main() {
  runApp(const LeoTrackerApp());
}

class LeoTrackerApp extends StatefulWidget {
  const LeoTrackerApp({super.key});

  @override
  State<LeoTrackerApp> createState() => _LeoTrackerAppState();
}

class _LeoTrackerAppState extends State<LeoTrackerApp>
    with TickerProviderStateMixin {
  final Map<String, TrackerDevice> _devicesBySig = {};
  bool scanning = false;
  int pageIndex = 0;
  DateTime? lastScanTime;
  DateTime? scanStartTime;
  int _scanSession = 0;
  int _scanSecondsElapsed = 0;
  Timer? _scanTimer;
  DateTime _mainListClearTime = DateTime.fromMillisecondsSinceEpoch(0);
  StreamSubscription<TrackerDevice>? _bleSub;
  StreamSubscription<AccelerometerEvent>? _motionSub;

  double _lastMag = 0;
  final double _movementThreshold = 1.2;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _blinkCtrl;

  // 10-Second Sorting Validity State
  List<String> _displayOrder = [];
  DateTime _lastSortTime = DateTime.fromMillisecondsSinceEpoch(0);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey _scanButtonKey = GlobalKey();
  final GlobalKey _trackerListKey = GlobalKey();
  final GlobalKey _firstTrackerCardKey = GlobalKey();
  final GlobalKey _identifyTabsKey = GlobalKey();
  final GlobalKey _drawerFiltersKey = GlobalKey();
  final GlobalKey _drawerReportsKey = GlobalKey();
  BuildContext? _materialContext;
  bool _tutorialRunning = false;
  bool _tutorialClosedEarly = false;
  bool _missionChosenThisLaunch = false;

  TrackerDevice get _demoTutorialDevice {
    final now = DateTime.now().millisecondsSinceEpoch;
    return TrackerDevice(
      signature: 'tutorial-demo-airtag',
      id: 'tutorial-demo-airtag',
      logicalId: 'tutorial-demo-airtag',
      kind: 'AIRTAG',
      pinnedMac: 'D4:90:F6:D4:4B:4F',
      lastMac: 'D4:90:F6:D4:4B:4F',
      rssi: -61,
      distanceMeters: 1.95,
      firstSeenMs: now - 6000,
      lastSeenMs: now - 1200,
      sightings: 8,
      rotatingMacCount: 1,
      rawFrame: '1EFF4C00121900112233445566778899AABBCC',
      smoothedRssi: -61,
      localName: '',
      isConnectable: false,
      serviceUuids: [],
      rotatingMacCount: 0, // ← FIXED: required parameter added
    );
  }

  String get scanTimeLabel {
    final m = (_scanSecondsElapsed ~/ 60).toString();
    final s = (_scanSecondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startScanTimer() {
    _scanSecondsElapsed = 0;
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!scanning) {
        _scanTimer?.cancel();
        return;
      }
      setState(() => _scanSecondsElapsed++);
    });
  }

  void _resetScanTimer() {
    _scanTimer?.cancel();
    _scanSecondsElapsed = 0;
  }

  // Only clears devices from the main view, keeping advanced scanner intact
  Future<void> _clearMainList() async {
    setState(() {
      _mainListClearTime = DateTime.now();
    });
  }

    // Toggle the BLE scanning state when the user initiates a scan or stops it, managing the scan session and updating the UI accordingly
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _fadeCtrl.forward();

    _bleSub = BleBridge.detections.listen((device) async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await DeviceMarks.restoreUndesignated(device.stableKey);

      setState(() {
        final prev = _devicesBySig[device.signature];
        _devicesBySig[device.signature] = prev == null
            ? device
            : prev.merge(device);

        _heldPeakRssi[device.signature] = max(
          _heldPeakRssi[device.signature] ?? device.smoothedRssi,
          device.smoothedRssi,
        );
        _heldPeakUntilMs[device.signature] = now + 10000;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      _checkFirstLaunchTutorial();
    });
  }

  void _showMissionPrompt() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Select Mission Profile',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
              ),
              onPressed: () {
                FiltersModel.apply(
                  maxMainDistanceFt: 10.0,
                  maxAdvancedDistanceFt: 40.0,
                  minRssi: -100,
                  filterByRssi: true,
                  rssiThreshold: -70,
                  sortMode: SortMode.recent,
                );
                Navigator.pop(ctx);
              },
              child: const Text(
                'Package Mission\nI’m determining if there is a tag inside of a sealed package.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
              ),
              onPressed: () {
                FiltersModel.apply(
                  maxMainDistanceFt: 50.0,
                  maxAdvancedDistanceFt: 200.0,
                  minRssi: -100,
                  filterByRssi: true,
                  rssiThreshold: -90,
                  sortMode: SortMode.recent,
                );
                Navigator.pop(ctx);
              },
              child: const Text(
                'Hunting Mission\nI\'m hunting for a possible tag in a known area such as a vehicle or backpack.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 10-Second RSSI validity sorting
  List<TrackerDevice> get devices {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Refresh sort every 2 seconds so "last seen" updates smoothly
    if (now.difference(_lastSortTime).inSeconds >= 2 || _displayOrder.isEmpty) {
      final list = _devicesBySig.values.toList()
        ..sort((a, b) => b.smoothedRssi.compareTo(a.smoothedRssi));
      _displayOrder = list.map((d) => d.signature).toList();
      _lastSortTime = now;
    }

    // Only show devices that have been seen for at least 10 seconds
    return _displayOrder
        .where(_devicesBySig.containsKey)
        .map((sig) => _devicesBySig[sig]!)
        .where((d) => nowMs - d.firstSeenMs >= 10000) // ← 10 second hold
        .toList();
  }

  // Toggle the BLE scanning state when the user initiates a scan or stops it, managing the scan session and updating the UI accordingly
  Future<void> toggleScan() async {
    if (_tutorialRunning) return;

    if (scanning) {
      await BleBridge.stopScan();
      await _motionSub?.cancel();
      _motionSub = null;
      _blinkCtrl.stop();

      setState(() {
        scanning = false;
        lastScanTime = DateTime.now();
        scanStartTime = null;
      });
      _resetScanTimer();
      return;
    }
    final mySession = ++_scanSession;
    try {
      final ok = await BleBridge.startScan();
      if (!ok) {
        if (!mounted || _scanSession != mySession) return;
        await _motionSub?.cancel();
        _motionSub = null;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bluetooth is not ready')));
        setState(() {
          scanning = false;
          lastScanTime = DateTime.now();
          scanStartTime = null;
        });
        _resetScanTimer();
        return;
      }
    } catch (_) {
      if (!mounted || _scanSession != mySession) return;
      await _motionSub?.cancel();
      _motionSub = null;
      setState(() {
        scanning = false;
        lastScanTime = DateTime.now();
        scanStartTime = null;
      });
      _resetScanTimer();
      return;
    }
    if (!mounted || _scanSession != mySession) return;
    setState(() {
      scanning = true;
      scanStartTime = DateTime.now();
    });
    _startMotionDetection();
    _startScanTimer();
  }

  // Start motion detection to monitor device movement and potentially trigger BLE scans based on significant changes in accelerometer data
  void _startMotionDetection() {
    _motionSub = accelerometerEventStream().listen((event) {
      if (!scanning) return;

      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      final delta = (magnitude - _lastMag).abs();
      _lastMag = magnitude;

      if (delta > _movementThreshold) {
        // Continuous BLE scan already active.
      }
    });
  }

  Future<void> _checkFirstLaunchTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_quick_start_guide') ?? false;

    if (!mounted) return;
    if (_materialContext == null) return;

    setState(() {
      _missionChosenThisLaunch = false;
    });

    if (seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showMissionPrompt());
      return;
    }

    await _showTutorialStartPrompt();
  }

  Future<void> _markTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_quick_start_guide', true);
  }

  void _closeEntireTutorial() {
    _tutorialClosedEarly = true;
    if (_navigatorKey.currentState != null) {
      _navigatorKey.currentState!.popUntil((route) => route.isFirst);
    }
  }

  Future<void> _showTutorialStartPrompt() async {
    final dialogContext = _materialContext;
    if (dialogContext == null) return;

    await showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Quick Start Guide',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Would you like a quickstart walkthrough of the app?',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _markTutorialSeen();
              if (_navigatorKey.currentState != null)
                _navigatorKey.currentState!.pop();
              _showMissionPrompt();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_navigatorKey.currentState != null)
                _navigatorKey.currentState!.pop();
              Future.delayed(const Duration(milliseconds: 250), () {
                _markTutorialSeen();
                _startQuickGuide();
              });
            },
            child: const Text('Start Guide'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showCoach(List<TargetFocus> targets) async {
    final coachContext = _materialContext;
    if (coachContext == null || targets.isEmpty) return false;

    final completer = Completer<bool>();

    final coach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.78,
      paddingFocus: 10,
      hideSkip: true,
      onClickTarget: (target) {
        // Tapping the target advances the tutorial
      },
      onFinish: () {
        if (!completer.isCompleted) completer.complete(true);
      },
      onSkip: () {
        if (!completer.isCompleted) completer.complete(false);
        return true;
      },
    );

    await Future.delayed(const Duration(milliseconds: 100));
    coach.show(context: coachContext);
    return completer.future;
  }

  Future<void> _startQuickGuide() async {
    if (_tutorialRunning || !mounted) return;
    if (scanning) {
      await BleBridge.stopScan();
      await _motionSub?.cancel();
      _motionSub = null;
      _blinkCtrl.stop();
      setState(() {
        scanning = false;
        lastScanTime = DateTime.now();
        scanStartTime = null;
      });
    }
    setState(() {
      pageIndex = 0;
      _tutorialRunning = true;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    await _runDistanceTutorial();
    if (!mounted) return;
    await _openSearchTutorialFromDemoTracker();
    if (!mounted) return;
    setState(() => pageIndex = 1);
    await Future.delayed(const Duration(milliseconds: 900));
    await _runClassifyTutorial();
    if (!mounted) return;
    await _runDrawerTutorial();
    if (!mounted) return;
    setState(() {
      pageIndex = 0;
      _tutorialRunning = false;
    });
    _showMissionPrompt();
  }

  // Force sequence: scan button -> tracker list -> open tracker card
  Future<void> _runDistanceTutorial() async {
    await _showCoach([
      tutorialTarget(
        key: _scanButtonKey,
        id: 'scan_button',
        title: 'Start and stop scanning',
        body: 'Press Scan here to stop and start device scanning.',
        showSkip: false,
      ),
      tutorialTarget(
        key: _firstTrackerCardKey,
        id: 'open_tracker',
        title: 'Open a tag',
        body: 'Tap a tag to open the detailed search page.',
        showSkip: false,
      ),
    ]);
  }

  Future<void> _openSearchTutorialFromDemoTracker() async {
    final navContext = _materialContext;
    if (navContext == null || _tutorialClosedEarly) return;

    await Future.delayed(const Duration(milliseconds: 250));

    await Navigator.push(
      navContext,
      MaterialPageRoute(
        builder: (_) =>
            SearchPage(device: _demoTutorialDevice, tutorialMode: true),
      ),
    );
  }

  Future<void> _runIdentifyTutorial() async {
    await _showCoach([
      tutorialTarget(
        key: _identifyTabsKey,
        id: 'identify_tabs',
        title: 'Classified tags',
        body:
            'Tags can be moved into undesignated, friendly, nonsuspect, or suspect.',
        showSkip: false,
      ),
    ]);
  }

  Future<void> _runDrawerTutorial() async {
    _scaffoldKey.currentState?.openDrawer();
    await Future.delayed(const Duration(milliseconds: 600));

    await _showCoach([
      tutorialTarget(
        key: _drawerQuickStartKey,
        id: 'drawer_quick_start',
        title: 'Quick Start',
        body: 'Use this to rerun the tutorial any time.',
        showSkip: false,
      ),
      tutorialTarget(
        key: _drawerGuidanceKey,
        id: 'drawer_guidance',
        title: 'LEO Guidance',
        body: 'Open law-enforcement guidance here.',
        showSkip: false,
      ),
      tutorialTarget(
        key: _drawerFiltersKey,
        id: 'drawer_filters',
        title: 'Filters',
        body: 'Use filters to control search behavior.',
        showSkip: false,
      ),
      tutorialTarget(
        key: _drawerReportsKey,
        id: 'drawer_reports',
        title: 'Reports page',
        body: 'Saved suspect or found reports show up here.',
        showSkip: false,
      ),
      tutorialTarget(
        key: _drawerAdvancedKey,
        id: 'drawer_advanced',
        title: 'Advanced Features',
        body: 'Use this area for clearing saved tag designations.',
        showSkip: false,
      ),
    ]);

    if (!mounted || _materialContext == null || _tutorialClosedEarly) return;
    Navigator.of(_materialContext!).pop();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Clean up resources such as animation controllers and stream subscriptions when the widget is disposed to prevent memory leaks
  @override
  void dispose() {
    _fadeCtrl.dispose();
    _blinkCtrl.dispose();
    _motionSub?.cancel();
    _bleSub?.cancel();
    super.dispose();
  }

  // Build the main UI of the app, including the navigation between different pages (DistancePage and IdentificationPage) and displaying the list of detected devices based on the current filters and sorting options
  @override
  Widget build(BuildContext context) {
    final trackedDevices = devices
        .where(
          (d) =>
              d.isLikelyAirTag ||
              d.isLikelyFindMy ||
              d.isLikelyTile ||
              d.isLikelySamsung,
        )
        .toList();

    final tutorialTrackedDevices = _tutorialRunning
        ? <TrackerDevice>[_demoTutorialDevice]
        : trackedDevices;

    return ValueListenableBuilder<FiltersState>(
      valueListenable: FiltersModel.notifier,
      builder: (_, filters, __) {
        final unmarkedDevices = devices
            .where((d) => DeviceMarks.getMark(d.signature) == null)
            .toList();
        final advancedDevices = unmarkedDevices
            .where((d) => d.distanceFeet <= filters.maxAdvancedDistanceFt)
            .where((d) => d.rssi >= filters.minRssi)
            .where(
              (d) => !filters.filterByRssi || d.rssi >= filters.rssiThreshold,
            )
            .toList();
        final nearDevices =
            advancedDevices
                .where((d) => d.distanceFeet <= filters.maxMainDistanceFt)
                .where(
                  (d) =>
                      d.lastSeenMs >= _mainListClearTime.millisecondsSinceEpoch,
                )
                .toList()
              ..sort((a, b) => a.distanceFeet.compareTo(b.distanceFeet));

        return MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (materialContext) {
              _materialContext = materialContext;
              final pages = [
                DistancePage(
                  nearDevices: _tutorialRunning
                      ? tutorialTrackedDevices
                      : nearDevices,
                  allTrackedDevices: advancedDevices,
                  scanning: scanning,
                  onRescan: toggleScan,
                  lastScanTime: lastScanTime,
                  scanStartTime: scanStartTime,
                  scanCountdownLabel: scanTimeLabel,
                  onRefresh: _clearMainList,
                  scanButtonKey: _scanButtonKey,
                  trackerListKey: _trackerListKey,
                  firstTrackerCardKey: _firstTrackerCardKey,
                  tutorialMode: _tutorialRunning,
                  tutorialDevice: _demoTutorialDevice,
                ),
                IdentificationPage(
                  devices: _tutorialRunning ? tutorialTrackedDevices : devices,
                  classifyTabsKey: _classifyTabsKey,
                ),
              ];
              return FadeTransition(
                opacity: _fadeAnim,
                child: Scaffold(
                  key: _scaffoldKey,
                  drawer: AppDrawer(
                    filtersTileKey: _drawerFiltersKey,
                    reportsTileKey: _drawerReportsKey,
                    tutorialMode: _tutorialRunning,
                    onReplayTutorial: () {
                      // Close drawer first, then start tutorial
                      _scaffoldKey.currentState?.closeDrawer();
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) _startQuickGuide();
                      });
                    },
                  ),
                  appBar: AppBar(
                    leading: IconButton(
                      key: _drawerButtonKey,
                      icon: const Icon(Icons.menu, size: 30),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    centerTitle: true,
                    title: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              'assets/leo_splash.png',
                              height: 20,
                              width: 20,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LeoFindIt',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (scanning)
                            FadeTransition(
                              opacity: _blinkCtrl,
                              child: const Icon(
                                Icons.circle,
                                color: Colors.redAccent,
                                size: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  body: SafeArea(bottom: false, child: pages[pageIndex]),
                  bottomNavigationBar: SafeArea(
                    top: false,
                    child: BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      currentIndex: pageIndex,
                      selectedItemColor: Colors.blueAccent,
                      unselectedItemColor: Colors.grey,
                      selectedFontSize: 16,
                      unselectedFontSize: 12,
                      iconSize: 28,
                      onTap: (i) => setState(() => pageIndex = i),
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.radar),
                          label: 'Scan',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.list_alt),
                          label: 'Classification',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
