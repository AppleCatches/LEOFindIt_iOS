import 'package:flutter/material.dart';
import 'device_marks.dart';

class HiddenTagsPage extends StatefulWidget {
  const HiddenTagsPage({super.key});

  @override
  State<HiddenTagsPage> createState() => _HiddenTagsPageState();
}

class _HiddenTagsPageState extends State<HiddenTagsPage> {
  List<String> _hiddenKeys = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _hiddenKeys = DeviceMarks.dismissedUndesignatedKeys.toList()..sort();
    });
  }

  Future<void> _restoreOne(String key) async {
    await DeviceMarks.restoreUndesignated(key);
    _reload();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hidden tag restored.')),
    );
  }

  Future<void> _restoreAll() async {
    await DeviceMarks.clearDismissedUndesignated();
    _reload();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All hidden tags restored.')),
    );
  }

  String _shortKey(String key) {
    if (key.length <= 8) return key;
    return key.substring(key.length - 8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hidden Tags',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_hiddenKeys.isNotEmpty)
            TextButton(
              onPressed: _restoreAll,
              child: const Text('Restore All'),
            ),
        ],
      ),
      body: _hiddenKeys.isEmpty
          ? const Center(
        child: Text(
          'No hidden tags',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _hiddenKeys.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final key = _hiddenKeys[index];

          return Card(
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text(
                'Hidden tag',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'ID tail: ${_shortKey(key)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              trailing: TextButton(
                onPressed: () => _restoreOne(key),
                child: const Text('Restore'),
              ),
            ),
          );
        },
      ),
    );
  }
}
