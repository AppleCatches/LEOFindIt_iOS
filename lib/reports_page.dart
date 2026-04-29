import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'reports_store.dart';
import 'app_tutorial.dart';

class ReportsPage extends StatefulWidget {
  final bool tutorialMode;

  const ReportsPage({
    super.key,
    this.tutorialMode = false,
  });

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String? _savedReportId;
  final TextEditingController _feedbackCtrl = TextEditingController();

  final GlobalKey _reportsAreaKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    if (widget.tutorialMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 350));
        await _runTutorial();
      });
    }
  }

  Future<bool> _showCoach(List<TargetFocus> targets) async {
    if (!mounted || targets.isEmpty) return false;

    final completer = Completer<bool>();

    final coach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.78,
      paddingFocus: 10,
      hideSkip: true,
      onFinish: () {
        if (!completer.isCompleted) completer.complete(true);
      },
      onSkip: () {
        if (!completer.isCompleted) completer.complete(false);
        return true;
      },
    );

    coach.show(context: context);
    return completer.future;
  }

  Future<void> _runTutorial() async {
    await _showCoach([
      tutorialTarget(
        key: _reportsAreaKey,
        id: 'reports_area',
        title: 'Reports',
        body: 'Suspect tracker reports will show up here and can be saved to your device.',
      ),
    ]);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _dismissFeedback() {
    setState(() {
      _savedReportId = null;
      _feedbackCtrl.clear();
    });
  }

  Future<void> _confirmClearAll() async {
    final alsoDeleteFiles = await showDialog<bool>(
      context: context,
      builder: (_) {
        bool deleteFiles = false;
        return AlertDialog(
          title: const Text("Clear all reports?"),
          content: StatefulBuilder(
            builder: (ctx, setSt) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("This removes all reports from the app."),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: deleteFiles,
                  onChanged: (v) => setSt(() => deleteFiles = v ?? false),
                  title: const Text(
                    "Also delete exported files from Downloads",
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, deleteFiles),
              child: const Text("Clear"),
            ),
          ],
        );
      },
    );

    if (alsoDeleteFiles == null) return;

    await ReportsStore.clearAll(alsoDeleteExportedFiles: alsoDeleteFiles);
    if (!mounted) return;

    _dismissFeedback();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cleared all reports.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TrackerReport>>(
      valueListenable: ReportsStore.notifier,
      builder: (_, reports, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Reports"),
            actions: [
              if (reports.isNotEmpty)
                IconButton(
                  tooltip: "Clear all",
                  onPressed: _confirmClearAll,
                  icon: const Icon(Icons.delete_sweep_rounded),
                ),
            ],
          ),
          body: ListView(
            key: _reportsAreaKey,
            padding: const EdgeInsets.all(12),
            children: [
              if (reports.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text("No reports yet."),
                )
              else
                ...reports.map((r) {
                  final short = r.signature.length >= 8
                      ? r.signature.substring(0, 8)
                      : r.signature;

                  final hasAnyExport = ((r.exportedUriJson ?? "").isNotEmpty) ||
                      ((r.exportedUriTxt ?? "").isNotEmpty);

                  return Card(
                    child: ListTile(
                      title: Text("${r.kind} • $short"),
                      subtitle: Text(
                        "${r.createdAt} • RSSI ${r.rssi} dBm • ${(r.distanceMeters * 3.28084).toStringAsFixed(1)} ft",
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == "save_txt") {
                            try {
                              await ReportsStore.saveCaseReportTxtToDownloads(r);
                              if (!mounted) return;

                              setState(() => _savedReportId = r.reportId);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Saved Case Report to Downloads/LEOFindIt (.txt)",
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Save failed: $e")),
                              );
                            }
                          }

                          if (v == "save_json") {
                            try {
                              await ReportsStore.saveRawJsonToDownloads(r);
                              if (!mounted) return;

                              setState(() => _savedReportId = r.reportId);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Saved Raw Evidence to Downloads/LEOFindIt (.json)",
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Save failed: $e")),
                              );
                            }
                          }

                          if (v == "delete_local") {
                            await ReportsStore.deleteReport(r.reportId);
                            if (!mounted) return;
                            if (_savedReportId == r.reportId) _dismissFeedback();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Report removed from app."),
                              ),
                            );
                          }

                          if (v == "delete_both") {
                            await ReportsStore.deleteReport(
                              r.reportId,
                              alsoDeleteExportedFiles: true,
                            );
                            if (!mounted) return;
                            if (_savedReportId == r.reportId) _dismissFeedback();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Report removed (and attempted file delete).",
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: "save_txt",
                            child: Text("Save Case Report (Text)"),
                          ),
                          const PopupMenuItem(
                            value: "save_json",
                            child: Text("Save Raw Evidence (JSON)"),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: "delete_local",
                            child: Text("Delete from app"),
                          ),
                          PopupMenuItem(
                            value: "delete_both",
                            enabled: hasAnyExport,
                            child: const Text("Delete app + exported files"),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              // Feedback prompt after saving (TXT or JSON)
              if (_savedReportId != null) ...[
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  "Please let the software team know what happened in this case, including any feedback. (No PII or sensitive info!)",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _feedbackCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText:
                    "What happened? Any scanner/UI issues? Steps to reproduce?",
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _dismissFeedback,
                        child: const Text("No thanks"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final txt = _feedbackCtrl.text.trim();
                          if (txt.isEmpty) {
                            _dismissFeedback();
                            return;
                          }

                          await ReportsStore.updateFeedback(_savedReportId!, txt);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Feedback saved.")),
                          );

                          _dismissFeedback();
                        },
                        child: const Text("Save feedback"),
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        );
      },
    );
  }
}
