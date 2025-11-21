import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const LEOFindItApp());
}

class LEOFindItApp extends StatelessWidget {
  const LEOFindItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LEOFindIt',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ScanScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const platform = MethodChannel('com.ios.leofindit/bluetooth');
  static const eventChannel = EventChannel('com.ios.leofindit/bluetoothStream');

  List<Map<String, dynamic>> devices = [];
  bool scanning = false;
  bool testMode = true; // Default to test mode since no iPhone yet

  Future<void> startScan() async {
    setState(() {
      devices.clear();
      scanning = true;
    });

    if (testMode || Platform.isMacOS) {
      _startMockScan();
    } else {
      try {
        await platform.invokeMethod('startScan');
      } catch (_) {
        _startMockScan();
      }
    }
  }

  Future<void> stopScan() async {
    setState(() => scanning = false);

    if (!testMode && Platform.isIOS) {
      await platform.invokeMethod('stopScan');
    }
  }

  void _startMockScan() {
    // Fake BLE devices for testing without iPhone
    devices = [
      {"name": "Test AirTag", "id": "0001", "rssi": -50},
      {"name": "Test Tile Tracker", "id": "0002", "rssi": -80},
      {"name": "Unknown BLE Device", "id": "0003", "rssi": -65},
    ];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (!testMode && Platform.isIOS) {
      eventChannel.receiveBroadcastStream().listen((event) {
        setState(() {
          devices.add(Map<String, dynamic>.from(event));
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LEOFindIt Scanner')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Test Mode (Simulator)'),
            value: testMode,
            onChanged: (value) {
              setState(() {
                testMode = value;
                devices.clear();
              });
            },
          ),
          ElevatedButton(
            onPressed: scanning ? stopScan : startScan,
            child: Text(scanning ? 'Stop Scan' : 'Start Scan'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];
                return ListTile(
                  title: Text(d['name']),
                  subtitle: Text('RSSI: ${d['rssi']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
