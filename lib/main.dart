// ---------------------------
// LEOFindIt_iOS/lib/main.dart
// ---------------------------
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
  // match channels used on swift side
  static const platform = MethodChannel('com.leofindit/bluetooth');
  static const eventChannel = EventChannel('com.leofindit/bluetoothStream');

  bool testMode = false; // toggleable test mode
  bool scanning = false;
  // final bool testMode = !Platform.isIOS; // Uncomment when testing on iPhone

  String bluetoothStatus = "Idle"; // simple status text
  List<Map<String, dynamic>> devices = [];
  List<Map<String, dynamic>> savedDevices = []; // "marked as found"

  // MOCK SCANNING SUPPORT (for iOS simulator)
  Timer? mockTimer;
  bool mockScanning = false;

  Future<void> startScan() async {
    devices.clear();
    setState(() {
      // devices.clear();
      scanning = true;
      bluetoothStatus = "Scanning...";
    });

    if (testMode || Platform.isMacOS) {
      _startMockScan();
      return;
    } //else {}

    try {
      await platform.invokeMethod('startScan');
    } catch (e) {
      // _startMockScan();
      setState(() => bluetoothStatus = "ERROR: Missing native BLE support");
    }
  }

  Future<void> stopScan() async {
  setState(() {
    scanning = false;
    bluetoothStatus = "Scan stopped";
  });

  // Stop mock scanning if simulator/test mode
  if (mockScanning) {
    mockScanning = false;
    mockTimer?.cancel();
    return;
  }

  // Real iPhone scanning
  if (!testMode && Platform.isIOS) {
    await platform.invokeMethod('stopScan');
  }
}


  void _startMockScan() {
    // Fake BLE devices for testing without iPhone
    mockScanning = true;
    devices.clear();
    int counter = 0;

    final mockList = [
      {"name": "Test AirTag", "id": "0001", "rssi": -50},
      {"name": "Samsung SmartTag", "id": "0002", "rssi": -70},
      {"name": "Tile Tracker", "id": "0003", "rssi": -80},
    ];

    mockTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mockScanning) {
        timer.cancel();
        return;
      }

      if (counter < mockList.length) {
        setState(() {
          devices.add(mockList[counter]);
          bluetoothStatus = "Mock scanning… found ${devices.length} device(s)";
        });
        counter++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Listen to native BLE scan results
    if (!testMode && Platform.isIOS) {
      eventChannel.receiveBroadcastStream().listen((event) {
        setState(() {
          devices.add(Map<String, dynamic>.from(event));
          bluetoothStatus = "Found ${devices.length} device(s)";
        });
      });
    }
  }

  // convert RSSI to simple "signal strength"
  String _rssiLabel(dynamic value) {
    if (value == null) return "Unknown";

    final int rssi = value is int
        ? value
        : int.tryParse(value.toString()) ?? -100;
    if (rssi >= -45) {
      return "Very Strong";
    } else if (rssi >= -60) {
      return "Strong";
    } else if (rssi >= -75) {
      return "Moderate";
    } else if (rssi >= -90) {
      return "Weak";
    } else {
      return "Very Weak";
    }
  }

  IconData _rssiIcon(dynamic value) {
    if (value == null) return Icons.signal_wifi_off;

    final int rssi = value is int
        ? value
        : int.tryParse(value.toString()) ?? -100;

    if (rssi >= -45) {
      return Icons.signal_wifi_4_bar; // very strong
    } else if (rssi >= -60) {
      return Icons.signal_wifi_3_bar; // strong
    } else if (rssi >= -75) {
      return Icons.signal_wifi_2_bar; // moderate
    } else if (rssi >= -90) {
      return Icons.signal_wifi_1_bar; // weak
    } else {
      return Icons.signal_wifi_0_bar; // very weak
    }
  }

  void _markDeviceFound(Map<String, dynamic> device) {
    final alreadySaved = savedDevices.any((d) => d["id"] == device["id"]);
    if (!alreadySaved) {
      setState(() {
        devices.remove(device);
        savedDevices.add(device);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved "${device["name"] ?? "Unknown Device"}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LEOFindIt Scanner'), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Row with Test Mode toggle and status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.science),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Test Mode (Simulated BLE)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: testMode,
                  onChanged: (value) {
                    setState(() {
                      testMode = value;
                      devices.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Test Mode enabled (using fake devices)'
                              : 'Real Mode selected (requires iPhone & BLE)',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Start / Stop Scan Button
          ElevatedButton(
            onPressed: scanning ? stopScan : startScan,
            child: Text(scanning ? 'Stop Scan' : 'Start Scan'),
          ),

          const SizedBox(height: 8),

          const Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              bluetoothStatus,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),

          // Devices List Label
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nearby Devices',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Display Devices
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, i) {
                final d = devices[i];
                final rssi = d["rssi"];
                return ListTile(
                  leading: Icon(_rssiIcon(rssi)),
                  title: Text(d["name"] ?? "Unknown Device"),
                  subtitle: Text(
                    "ID: ${d["id"]} • RSSI: $rssi dBm • ${_rssiLabel(rssi)}",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DeviceDetailScreen(
                          device: d,
                          onMarkFound: _markDeviceFound,
                          testMode: testMode, // pass test mode
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Saved Devices (simple in-memory list)
          if (savedDevices.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved Devices (Marked as Found)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: savedDevices.length,
                itemBuilder: (context, i) {
                  final d = savedDevices[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(d["name"] ?? "Unknown Device"),
                    subtitle: Text("ID: ${d["id"]}"),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DeviceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> device;
  final void Function(Map<String, dynamic>) onMarkFound;
  final bool testMode;

  // use same channel as main for potential BLE actions
  static const platform = MethodChannel('com.leofindit/bluetooth');

  const DeviceDetailScreen({
    super.key,
    required this.device,
    required this.onMarkFound,
    required this.testMode,
  });

  @override
  Widget build(BuildContext context) {
    final name = device["name"] ?? "Unknown Device";
    final id = device["id"] ?? "Unknown ID";
    final rssi = device["rssi"] ?? "Unknown";

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Device Name: $name",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text("Device ID: $id"),
            const SizedBox(height: 8),

            Text("Signal Strength (RSSI): ${rssi ?? "Unknown"} dBm"),
            const SizedBox(height: 8),

            Text(
              "Approximate Signal: ${_rssiLabelStatic(rssi)}",
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),

            Text(
              "Approximate Distance: ${_distanceEstimate(rssi)}",
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),

            // Make It Sing (simulated for now)
            ElevatedButton.icon(
              onPressed: () async {
                if (testMode || !Platform.isIOS) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Simulating "Make It Sing" – will be wired to real BLE on device.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await platform.invokeMethod('makeItSing', {"id": id});
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sent "Make It Sing" to $name')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ERROR Failed to make it sing: $e')),
                  );
                }
              },

              icon: const Icon(Icons.volume_up),
              label: const Text('Make It Sing'),
            ),

            const SizedBox(height: 12),

            // Mark As Found (saves into in-memory list)
            ElevatedButton.icon(
              onPressed: () {
                onMarkFound(device);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('Mark as Found'),
            ),
          ],
        ),
      ),
    );
  }

  static String _rssiLabelStatic(dynamic value) {
    final int rssi = value is int
        ? value
        : int.tryParse(value.toString()) ?? -100;

    if (rssi >= -45) return "Very Strong";
    if (rssi >= -60) return "Strong";
    if (rssi >= -75) return "Moderate";
    if (rssi >= -90) return "Weak";
    return "Very Weak";
  }

  static String _distanceEstimate(dynamic value) {
    final int rssi = value is int
        ? value
        : int.tryParse(value.toString()) ?? -100;

    // Rough estimates based on RSSI values
    if (rssi >= -45) return "~0–1 m (very close)";
    if (rssi >= -60) return "~1–3 m (nearby)";
    if (rssi >= -75) return "~3–5 m (in the room)";
    if (rssi >= -90) return "~5–10 m (far)";

    return ">10 m or obstructed";
  }
}
