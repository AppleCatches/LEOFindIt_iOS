import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'app_drawer.dart';
import 'ble_bridge.dart';
import 'device_marks.dart';
import 'distance_page.dart';
import 'filters.dart';
import 'identification_page.dart';
import 'models.dart';
import 'reports_store.dart';
import 'reports_page.dart';

// Initialize the app and manage the overall state
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DeviceMarks.init();
  await ReportsStore.init();
  runApp(const LeoTrackerApp());
}

// The LeoTrackerApp widget uses a StatefulWidget to maintain and update the state as the user interacts with the app and as new devices are detected through BLE scanning
class LeoTrackerApp extends StatefulWidget {
  const LeoTrackerApp({super.key});

  @override
  State<LeoTrackerApp> createState() => _LeoTrackerAppState();
}

// List of detected devices, scanning status, and user interactions such as starting/stopping scans and navigating between pages
class _LeoTrackerAppState extends State<LeoTrackerApp>
    with SingleTickerProviderStateMixin {
  final Map<String, TrackerDevice> _devicesBySig = {};

  int _scanSession = 0;
  bool scanning = false;
  int pageIndex = 0;
  DateTime? lastScanTime;

  int _scanSecondsElapsed = 0;
  Timer? _scanTimer;
  DateTime _mainListClearTime = DateTime.fromMillisecondsSinceEpoch(0);

  StreamSubscription<TrackerDevice>? _bleSub;
  StreamSubscription<AccelerometerEvent>? _motionSub;
  double _lastMag = 0;
  final double _movementThreshold = 1.2;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

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

    _bleSub = BleBridge.detections.listen((device) {
      setState(() {
        final prev = _devicesBySig[device.signature];
        _devicesBySig[device.signature] = prev == null
            ? device
            : prev.merge(device);
      });
    });
  }

  // Get the list of detected devices, sorted by the time they were first seen, to be displayed in the app's UI
  List<TrackerDevice> get devices =>
      _devicesBySig.values.toList()
        ..sort((a, b) => a.firstSeenMs.compareTo(b.firstSeenMs));

  // Toggle the BLE scanning state when the user initiates a scan or stops it, managing the scan session and updating the UI accordingly
  Future<void> toggleScan() async {
    if (scanning) {
      _scanSession++;

      await BleBridge.stopScan();
      await _motionSub?.cancel();
      _motionSub = null;

      if (!mounted) return;
      setState(() {
        scanning = false;
        lastScanTime = DateTime.now();
      });
      _resetScanTimer();
      return;
    }

    final mySession = ++_scanSession;

    // Start the BLE scan and handle the scanning state, including error handling if the scan fails to start, and updating the UI to reflect the current scanning status
    unawaited(() async {
      try {
        final ok = await BleBridge.startScan();

        if (!ok) {
          if (!mounted || _scanSession != mySession) return;

          await _motionSub?.cancel();
          _motionSub = null;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bluetooth is not ready')),
          );

          setState(() {
            scanning = false;
            lastScanTime = DateTime.now();
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
        });
        _resetScanTimer();
        return;
      }

      if (!mounted || _scanSession != mySession) return;
      setState(() => scanning = true);
      _startMotionDetection();
      _startScanTimer();

      /*
      // await Future.delayed(const Duration(minutes: 5));
      if (!mounted || _scanSession != mySession) return;

      await BleBridge.stopScan();
      await _motionSub?.cancel();
      _motionSub = null;

      if (!mounted || _scanSession != mySession) return;
      setState(() {
        scanning = false;
        lastScanTime = DateTime.now();
      });
      _resetScanTimer();
      */
    }());
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
        // BLE scan already running continuously
      }
    });
  }

  // Clean up resources such as animation controllers and stream subscriptions when the widget is disposed to prevent memory leaks
  @override
  void dispose() {
    _fadeCtrl.dispose();
    _motionSub?.cancel();
    _bleSub?.cancel();
    _scanTimer?.cancel();
    super.dispose();
  }

  // Build the main UI of the app, including the navigation between different pages (DistancePage and IdentificationPage) and displaying the list of detected devices based on the current filters and sorting options
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FiltersState>(
      valueListenable: FiltersModel.notifier,
      builder: (_, filters, __) {
        final advancedDevices = devices
            .where((d) => d.distanceFeet <= filters.maxAdvancedDistanceFt)
            .where((d) => d.rssi >= filters.minRssi)
            /*
            .where(
              (d) =>
                  !filters.hideConnectableNonTrackers || !d.looksLikeNonTracker,
            )
            */
            .where(
              (d) => !filters.filterByRssi || d.rssi >= filters.rssiThreshold,
            )
            .toList();

        switch (filters.sortMode) {
          case SortMode.recent:
            advancedDevices.sort(
              (a, b) => b.lastSeenMs.compareTo(a.lastSeenMs),
            );
            break;
          case SortMode.distanceAsc:
            advancedDevices.sort(
              (a, b) => a.distanceFeet.compareTo(b.distanceFeet),
            );
            break;
        }

        final nearDevices =
            advancedDevices
                .where((d) => d.distanceFeet <= filters.maxMainDistanceFt)
                .toList()
              ..sort((a, b) => a.distanceFeet.compareTo(b.distanceFeet));

        final pages = [
          DistancePage(
            nearDevices: nearDevices,
            allTrackedDevices: advancedDevices,
            scanning: scanning,
            onRescan: toggleScan,
            lastScanTime: lastScanTime,
            scanCountdownLabel: scanTimeLabel,
            onRefresh: _clearMainList,
          ),
          IdentificationPage(devices: advancedDevices),
        ];

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: FadeTransition(
            opacity: _fadeAnim,
            child: Scaffold(
              drawer: const AppDrawer(),
              appBar: AppBar(
                centerTitle: true,
                title: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/leo_splash.png',
                          height: 30,
                          width: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LEOFindIt',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.grey,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.7,
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
                      label: 'Identify',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
