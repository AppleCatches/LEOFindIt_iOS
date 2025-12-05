// ---------------------------
// File: LEOFindIt_iOS/lib/main.dart
// ---------------------------
import 'dart:async';
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
  static const MethodChannel _methodChannel = MethodChannel(
    'com.leofindit/bluetooth',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.leofindit/bluetoothStream',
  );

  final List<Map<String, dynamic>> _devices = [];
  StreamSubscription? _eventSub;

  String _status = "Idle";

  @override
  void initState() {
    super.initState();

    _eventSub = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        final data = Map<String, dynamic>.from(event);

        // Error from iOS (e.g., Bluetooth not ready)
        if (data["type"] == "error") {
          final code = data["code"] ?? "unknown_error";
          setState(() {
            if (code == "bluetooth_not_ready") {
              _status = "Bluetooth not ready — turn it on in Settings first.";
            } else {
              _status = "Error: $code";
            }
          });
          return;
        }

        // Device update
        if (data["type"] == "device") {
          setState(() {
            _devices.add(data);
            _status = "Found ${_devices.length} device(s)";
          });
        }
      },
      onError: (e) {
        setState(() {
          _status = "Stream error: $e";
        });
      },
    );
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    try {
      await _methodChannel.invokeMethod('startScan');
      setState(() {
        _devices.clear();
        _status = "Scanning…";
      });
    } catch (e) {
      setState(() {
        _status = "Failed to start scan: $e";
      });
    }
  }

  Future<void> _stopScan() async {
    try {
      await _methodChannel.invokeMethod('stopScan');
      setState(() {
        _status = "Scan stopped";
      });
    } catch (e) {
      setState(() {
        _status = "Failed to stop scan: $e";
      });
    }
  }

  IconData _rssiIcon(int rssi) {
    if (rssi > -50) return Icons.signal_cellular_4_bar;
    if (rssi > -70) return Icons.signal_cellular_3_bar;
    if (rssi > -85) return Icons.signal_cellular_2_bar;
    return Icons.signal_cellular_1_bar;
  }

  String _rssiLabel(int rssi) {
    if (rssi > -50) return "Very close";
    if (rssi > -70) return "Near";
    if (rssi > -85) return "Far";
    return "Very far";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LEOFindIt – Tracker Scanner")),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            _status,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _devices.isEmpty
                ? const Center(
                    child: Text(
                      "No devices detected yet.\nPress \"Start Scan\" to begin.",
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final d = _devices[index];

                      final name = (d["name"] ?? "Unknown") as String;
                      final id = (d["id"] ?? "") as String;
                      final rssi = (d["rssi"] ?? -100) as int;

                      final score = ((d["airTagScore"] ?? 0.0) as num)
                          .toDouble();
                      final probability = ((d["probability"] ?? 0) as num)
                          .toInt();
                      final isSuspicious = (d["isSuspicious"] ?? false) as bool;

                      final seenSeconds = ((d["seenSeconds"] ?? 0) as num)
                          .toInt();
                      final sampleCount = ((d["sampleCount"] ?? 0) as num)
                          .toInt();
                      final isConnectable =
                          (d["isConnectable"] ?? false) as bool;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Icon(
                            _rssiIcon(rssi),
                            color: isSuspicious ? Colors.red : Colors.blue,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSuspicious ? Colors.red : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ID: $id"),
                              Text(
                                "RSSI: $rssi dBm • ${_rssiLabel(rssi)} • Samples: $sampleCount",
                              ),
                              Text(
                                "Connectable: ${isConnectable ? "Yes" : "No"} • Seen: ${seenSeconds}s",
                              ),
                              if (isSuspicious)
                                Text(
                                  "⚠ Possible Tracker (Score: ${score.toStringAsFixed(2)}, $probability%)",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                Text(
                                  "Tracker Probability: $probability%",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "start",
            onPressed: _startScan,
            backgroundColor: Colors.green,
            child: const Icon(Icons.search),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: "stop",
            onPressed: _stopScan,
            backgroundColor: Colors.red,
            child: const Icon(Icons.stop),
          ),
        ],
      ),
    );
  }
}
