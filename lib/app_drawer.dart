import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'quick_start_page.dart';
import 'advanced_search_help_page.dart';
import 'tips_page.dart';
import 'filters_page.dart';
import 'reports_page.dart';
import 'warrent_info_page.dart';

class AppDrawer extends StatefulWidget {
  final GlobalKey<State<StatefulWidget>>? filtersTileKey;
  final GlobalKey<State<StatefulWidget>>? reportsTileKey;

  const AppDrawer({super.key, this.filtersTileKey, this.reportsTileKey});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _appVersion = '';
  bool _isCheckingForUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  // Dynamically fetches the version string from Xcode / Android Build settings
  Future<void> _loadVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
      });
    }
  }

  // Routes the user to the App Store or Play Store
  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingForUpdate = true;
    });

    // Brief simulated network delay so the user sees the UI react
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isCheckingForUpdate = false;
    });

    // --- STORE LINK LOGIC ---
    // IMPORTANT: Replace 'YOUR_APP_STORE_ID' with your actual 10-digit Apple App Store ID
    // Replace 'com.leofindit.app' with your Google Play Store package name if different.
    const String appStoreId = 'YOUR_APP_STORE_ID';
    const String playStoreId = 'com.leofindit.app';

    final Uri storeUrl = Platform.isIOS
        ? Uri.parse("https://apps.apple.com/app/id$appStoreId")
        : Uri.parse(
            "https://play.google.com/store/apps/details?id=$playStoreId",
          );

    try {
      if (await canLaunchUrl(storeUrl)) {
        await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the app store.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error checking for updates.')),
        );
      }
    }
  }

  void _open(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const DrawerHeader(
                    child: Text(
                      'LeoFindIt',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                    child: Text(
                      "Help & Guidance",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.play_circle),
                    title: const Text("Quick Start"),
                    onTap: () => _open(context, const QuickStartPage()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text("Advanced Search"),
                    onTap: () => _open(context, const AdvancedSearchHelpPage()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: const Text("Warrant Info"),
                    onTap: () => _open(context, const WarrantInfoPage()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: const Text("Tips"),
                    onTap: () => _open(context, const TipsPage()),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                    child: Text(
                      "Tools",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ListTile(
                    key: widget.filtersTileKey,
                    leading: const Icon(Icons.tune),
                    title: const Text("Filters"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FiltersPage()),
                      );
                    },
                  ),
                  ListTile(
                    key: widget.reportsTileKey,
                    leading: const Icon(Icons.description_outlined),
                    title: const Text("Reports"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- DYNAMIC VERSION & UPDATE AREA ---
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 8.0,
              ),
              child: Column(
                children: [
                  Text(
                    _appVersion.isEmpty
                        ? 'Loading version...'
                        : 'Version $_appVersion',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _isCheckingForUpdate ? null : _checkForUpdates,
                    icon: _isCheckingForUpdate
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.system_update,
                            size: 18,
                            color: Colors.blueAccent,
                          ),
                    label: Text(
                      _isCheckingForUpdate
                          ? 'Checking...'
                          : 'Check for Updates',
                      style: const TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
