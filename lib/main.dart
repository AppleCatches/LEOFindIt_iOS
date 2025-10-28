// Flutter + Swift iOS Starter Scaffold for LEOFindIt

// ---------------------------
// File: lib/main.dart
// ---------------------------
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
  static const platform = MethodChannel('com.leofindit/bluetooth');
  List<Map<String, dynamic>> devices = [];
  bool scanning = false;

  Future<void> startScan() async {
    setState(() => scanning = true);
    await platform.invokeMethod('startScan');
  }

  Future<void> stopScan() async {
    await platform.invokeMethod('stopScan');
    setState(() => scanning = false);
  }

  @override
  void initState() {
    super.initState();
    const eventChannel = EventChannel('com.leofindit/bluetoothStream');
    eventChannel.receiveBroadcastStream().listen((event) {
      setState(() {
        devices.add(Map<String, dynamic>.from(event));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LEOFindIt Scanner')),
      body: Column(
        children: [
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
                  title: Text(d['name'] ?? 'Unknown Device'),
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
