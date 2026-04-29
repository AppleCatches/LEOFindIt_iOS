import 'package:flutter/material.dart';
import 'device_marks.dart';
import 'hidden_tags_page.dart';
/*
class AdvancedFeaturesPage extends StatelessWidget {
  const AdvancedFeaturesPage({super.key});

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String body,
    required Future<void> Function() action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Advanced cleanup complete.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Advanced Features',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _SectionTitle('Management'),
          _ActionCard(
            icon: Icons.visibility_outlined,
            title: 'Manage hidden tags',
            subtitle: 'Restore tags you previously hid from the scan page.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HiddenTagsPage()),
              );
            },
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Danger zone'),
          _ActionCard(
            icon: Icons.delete_outline_rounded,
            title: 'Clear friendly tags',
            subtitle: 'Remove the Friendly designation from every saved tag.',
            onTap: () => _confirmAndRun(
              context,
              title: 'Clear all friendly tags?',
              body: 'This removes every Friendly designation saved in the app.',
              action: () => DeviceMarks.clearByMark(DeviceMark.friendly),
            ),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.delete_outline_rounded,
            title: 'Clear nonsuspect tags',
            subtitle: 'Remove the Nonsuspect designation from every saved tag.',
            onTap: () => _confirmAndRun(
              context,
              title: 'Clear all nonsuspect tags?',
              body:
                  'This removes every Nonsuspect designation saved in the app.',
              action: () => DeviceMarks.clearByMark(DeviceMark.nonsuspect),
            ),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.delete_outline_rounded,
            title: 'Clear suspect tags',
            subtitle: 'Remove the Suspect designation from every saved tag.',
            onTap: () => _confirmAndRun(
              context,
              title: 'Clear all suspect tags?',
              body: 'This removes every Suspect designation saved in the app.',
              action: () => DeviceMarks.clearByMark(DeviceMark.suspect),
            ),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.warning_amber_rounded,
            title: 'Clear all designated tags',
            subtitle: 'Remove every saved classification from every tag.',
            onTap: () => _confirmAndRun(
              context,
              title: 'Clear all designated tags?',
              body:
                  'This removes all saved Friendly, Nonsuspect, and Suspect designations.',
              action: () => DeviceMarks.clear(),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            elevation: 0,
            color: const Color(0xFFF8F7FA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Advanced cleanup actions were moved here so they are harder to trigger accidentally from the Classified Tags page.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
*/
