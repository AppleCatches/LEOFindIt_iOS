//For the hamburger menu feature
import 'package:flutter/material.dart';

import 'advanced_features_page.dart';
import 'filters_page.dart';
import 'guidance_page.dart';
import 'reports_page.dart';

class AppDrawer extends StatelessWidget {
  final GlobalKey? quickStartTileKey;
  final GlobalKey? guidanceTileKey;
  final GlobalKey? filtersTileKey;
  final GlobalKey? reportsTileKey;
  final GlobalKey? advancedTileKey;

  final VoidCallback? onQuickStart;

  const AppDrawer({
    super.key,
    this.quickStartTileKey,
    this.guidanceTileKey,
    this.filtersTileKey,
    this.reportsTileKey,
    this.advancedTileKey,
    this.onQuickStart,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Container(
          color: const Color(0xFFF3F1F5),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(22, 28, 22, 10),
                      child: Text(
                        'Help & Guidance',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                    _DrawerTile(
                      tileKey: quickStartTileKey,
                      icon: Icons.play_circle_fill_rounded,
                      title: 'Quick Start',
                      onTap: () {
                        Navigator.pop(context);
                        onQuickStart?.call();
                      },
                    ),
                    _DrawerTile(
                      tileKey: guidanceTileKey,
                      icon: Icons.shield_outlined,
                      title: 'LEO Guidance',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GuidancePage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(22, 28, 22, 10),
                      child: Text(
                        'Tools',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                    _DrawerTile(
                      tileKey: filtersTileKey,
                      icon: Icons.tune_rounded,
                      title: 'Filters',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FiltersPage(),
                          ),
                        );
                      },
                    ),
                    _DrawerTile(
                      tileKey: reportsTileKey,
                      icon: Icons.description_outlined,
                      title: 'Reports',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsPage(),
                          ),
                        );
                      },
                    ),
                    _DrawerTile(
                      tileKey: advancedTileKey,
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Advanced Features',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdvancedFeaturesPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                child: Text(
                  'Version 1.0.0+1',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final GlobalKey? tileKey;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      leading: Icon(
        icon,
        size: 34,
        color: const Color(0xFF4C4854),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111111),
        ),
      ),
      onTap: onTap,
    );
  }
}
