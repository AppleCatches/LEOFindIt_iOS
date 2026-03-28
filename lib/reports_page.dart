import 'package:flutter/material.dart';
import 'reports_store.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // String? _savedReportId;
  final TextEditingController _feedbackCtrl = TextEditingController();
  bool isSubmittingFeedback = false;

  Future<void> _submit() async {
    if (_feedbackCtrl.text.trim().isEmpty) return;

    setState(() => isSubmittingFeedback = true);

    // Send to Formspree via the store
    await ReportsStore.sendAnonymousFeedback(_feedbackCtrl.text);

    if (!mounted) return;
    setState(() {
      isSubmittingFeedback = false;
      _feedbackCtrl.clear(); // Clear the form after sending
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report sent successfully. Thank you!')),
    );
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Report')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Submit Anonymous Report',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Use this form to send plain-text feedback or a situational report to the development team. '
                'Please do not include any Personally Identifiable Information (PII) such as names, phone numbers, or emails.',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _feedbackCtrl,
                maxLines: 10,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Enter your report details or app feedback here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: isSubmittingFeedback
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    isSubmittingFeedback ? 'Sending...' : 'Send Report',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSubmittingFeedback ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
