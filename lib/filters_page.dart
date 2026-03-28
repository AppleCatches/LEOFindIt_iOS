import 'package:flutter/material.dart';
import 'filters.dart';

// The FiltersPage widget UI allows users to customize how detected devices are displayed based on distance, RSSI, and other criteria
class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

// The _FiltersPageState class manages the current values of all filter settings and the logic for applying those settings when the user confirms their choices
class _FiltersPageState extends State<FiltersPage> {
  late double mainDistance;
  late double advancedDistance;
  late double minRssi;
  // late bool hideConnectable;

  late bool filterByRssi;
  late int rssiThreshold;
  late SortMode sortMode;

  // Initialize the state of the filters ensuring that the UI reflects the current filter settings when opened
  @override
  void initState() {
    super.initState();
    final s = FiltersModel.state;
    mainDistance = s.maxMainDistanceFt;
    advancedDistance = s.maxAdvancedDistanceFt;
    minRssi = s.minRssi.toDouble();
    // hideConnectable = s.hideConnectableNonTrackers;
    filterByRssi = s.filterByRssi;
    rssiThreshold = s.rssiThreshold;
    sortMode = s.sortMode;
  }

  // Build the UI for applying the filters
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Filters")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text(
            'Main list distance (feet)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: mainDistance,
            min: 5,
            max: 50,
            divisions: 45,
            label: mainDistance.toStringAsFixed(0),
            onChanged: (v) => setState(() => mainDistance = v),
          ),
          Text('${mainDistance.toStringAsFixed(0)} ft'),

          const SizedBox(height: 20),
          const Text(
            'Advanced list distance (feet)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: advancedDistance,
            min: 20,
            max: 200, // Search up to 200ft
            divisions: 180,
            label: advancedDistance.toStringAsFixed(0),
            onChanged: (v) => setState(() => advancedDistance = v),
          ),
          Text('${advancedDistance.toStringAsFixed(0)} ft'),

          const SizedBox(height: 20),
          const Text(
            'Minimum RSSI',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: minRssi,
            min: -100,
            max: -40,
            divisions: 60,
            label: minRssi.toStringAsFixed(0),
            onChanged: (v) => setState(() => minRssi = v),
          ),
          Text('${minRssi.toStringAsFixed(0)} dBm'),

          /*
          SwitchListTile(
            title: const Text('Hide connectable non-trackers'),
            value: hideConnectable,
            onChanged: (v) => setState(() => hideConnectable = v),
          ),
          */
          const SizedBox(height: 24),
          const _SectionTitle("Filter"),
          _ToggleCard(
            title: "Filter by RSSI",
            subtitle:
                "Show only devices with RSSI stronger than your threshold.",
            value: filterByRssi,
            onChanged: (v) => setState(() => filterByRssi = v),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: filterByRssi
                  ? _RssiSlider(
                      value: rssiThreshold,
                      onChanged: (v) => setState(() => rssiThreshold = v),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 18),
          const _SectionTitle("Sorting"),

          _ToggleCard(
            title: "Most recently seen",
            subtitle:
                "Default. Keeps new detections near the top without constant jumping.",
            value: sortMode == SortMode.recent,
            onChanged: (v) {
              if (v) setState(() => sortMode = SortMode.recent);
            },
          ),

          const SizedBox(height: 10),

          _ToggleCard(
            title: "By distance",
            subtitle: "Closest → farthest (uses distance estimates).",
            value: sortMode == SortMode.distanceAsc,
            onChanged: (v) {
              if (v) setState(() => sortMode = SortMode.distanceAsc);
            },
          ),

          const SizedBox(height: 18),

          // Informational card explaining the "Suspect" label
          Card(
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Note: "Suspect" label is only shown when RSSI filter is ON and the device RSSI meets the threshold.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          // Apply Filters button that saves the current filter settings to the FiltersModel and closes the FiltersPage
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              FiltersModel.apply(
                maxMainDistanceFt: mainDistance,
                maxAdvancedDistanceFt: advancedDistance,
                minRssi: minRssi.round(),
                // hideConnectableNonTrackers: hideConnectable,
                filterByRssi: filterByRssi,
                rssiThreshold: rssiThreshold,
                sortMode: sortMode,
              );
              Navigator.pop(context);
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}

// Helper widget to display section titles for different groups of filter settings
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  // Build the UI to make it stand out from the other text in the FiltersPage and clearly indicate the start of a new group of filter settings
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

// Custom card widget that includes a title, subtitle, a toggle switch, and a group related filter options together in a visually appealing way
class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? child;

  // Constructor for creating a _ToggleCard instance with the specified title, subtitle, toggle value, onChanged callback, and optional child widget
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.child,
  });

  // Build the UI for the _ToggleCard, including the title, subtitle, toggle switch, and any child widget that should be displayed when the toggle is enabled
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
            if (child != null) ...[const SizedBox(height: 10), child!],
          ],
        ),
      ),
    );
  }
}

// Custom slider widget for adjusting the RSSI threshold, including an informational expansion tile with tips on how to interpret RSSI values and set the threshold effectively, used in the FiltersPage when the "Filter by RSSI" option is enabled
class _RssiSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RssiSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "RSSI threshold: $value dBm",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Slider(
          value: value.toDouble().clamp(-100.0, -30.0),
          min: -100,
          max: -30,
          divisions: 70,
          label: "$value dBm",
          onChanged: (v) => onChanged(v.round()),
        ),
        const SizedBox(height: 6),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(
              left: 2,
              right: 2,
              bottom: 6,
            ),
            title: Text(
              'Tips',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade800,
              ),
            ),
            children: const [
              _TipBullet(
                text: 'Less negative (e.g., -55) = closer / stronger signal.',
              ),
              SizedBox(height: 6),
              _TipBullet(
                text:
                    'You may want to keep the threshold high (more negative) if you suspect a tracker is obstructed by multiple barriers (e.g., in an inaccessible part of a car, hidden in a case, etc.).',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Helper widget to display individual tips as bullet points within the expansion tile in the _RssiSlider
class _TipBullet extends StatelessWidget {
  final String text;
  const _TipBullet({required this.text});

  // Build the UI for a single tip bullet point
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(Icons.circle, size: 6, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
