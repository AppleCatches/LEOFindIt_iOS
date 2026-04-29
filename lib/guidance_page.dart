import 'package:flutter/material.dart';

class GuidancePage extends StatelessWidget {
  const GuidancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_GuideSection>[
      _GuideSection(
        title: 'GUIDANCE FOR LEOs',
        body:
        'Use this section as a quick reference inside the app. Start with '
            '"FOUND TAG - DO THIS FIRST!" before moving to brand-specific steps.',
      ),
      _GuideSection(
        title: 'FOUND TAG - DO THIS FIRST!',
        body:
        'DO THIS FIRST WHEN AN ILLICIT TAG IS FOUND\n\n'
            'Process the found tag for fingerprints and DNA before handling.\n\n'
            'For an AirTag:\n'
            'Process the inside of the AirTag and its lithium battery for prints and DNA. '
            'Using gloves, hold the AirTag over a place that is fall safe. '
            'Squeeze it flat between the palms and rotate the silver side '
            'counterclockwise slightly until the silver cover becomes loose. '
            'Zoom in to photograph the serial number of the AirTag and ensure '
            'the photo is easy to read before fingerprinting.\n\n'
            'Then carefully process the inside of the battery cover, both sides '
            'of the battery, and the plastic side of the battery compartment for '
            'fingerprints and DNA. Offenders often remove the speaker on the printed '
            'circuit board, so carefully pry off the underside of the battery holder. '
            'Note: it is not difficult for an offender to swap this cover to mislead you. '
            'Include your LeoFindIt scan results with the UUID and MAC address plus date '
            'and time observed in your preservation request and warrant.',
      ),
      _GuideSection(
        title: 'FOUND APPLE AIRTAG',
        body:
        'FOR APPLE AIRTAGS (25 Days Retention)\n\n'
            '1. FIRST, complete DO THIS FIRST above to process for prints and DNA.\n\n'
            '2. Submit a preservation request ASAP using Apple\'s law-enforcement request form.\n\n'
            '3. Under Information Supporting Request, include:\n\n'
            'AirTag Serial Number: ____________________________\n'
            'UUID on LeoFindIt: ______________________________\n'
            'MAC on LeoFindIt: _______________________________\n'
            'Date UUID/MAC was scanned: ______________________\n'
            'Time UUID/MAC was scanned: ______________________  Time Zone: ____________\n'
            'Location where tag was found (address or gps coordinates): ______________________\n\n'
            '4. Under Information Requested from Apple, request preservation of paired-account '
            'details, identifiers, login metadata, associated devices, Find My connection logs, '
            'Find My transactional activity, and the UUID/MAC details tied to the date and time observed.\n\n'
            '5. Without delay, send the request form, the photo of the tag serial number, and '
            'a screenshot from LeoFindIt showing the UUID and MAC from your agency email address.\n\n'
            '6. Consider also sending the form, without PII, to leofindit@icloud.com so the '
            'programming team at Florida Gulf Coast University can receive feedback.\n\n'
            '7. Include the form with the case report attached to the warrant. The warrant '
            'should match the preservation-request bullets.\n\n'
            '8. IMPORTANT: Apple may notify the suspect unless a signed nondisclosure order '
            'is served with the warrant.',
      ),
      _GuideSection(
        title: 'FOUND SAMSUNG SMART TAG',
        body:
        'Samsung guidance section placeholder.\n\n'
            'Keep the same evidence-preservation approach: photograph the device, '
            'document UUID/MAC and scan time, preserve prints/DNA first, and export '
            'the LeoFindIt report before additional handling.',
      ),
      _GuideSection(
        title: 'FOUND LIFE360 TILE',
        body:
        'Life360 Tile guidance section placeholder.\n\n'
            'Keep the same evidence-preservation approach: photograph the device, '
            'document UUID/MAC and scan time, preserve prints/DNA first, and export '
            'the LeoFindIt report before additional handling.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LEO Guidance',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final s = sections[i];
          return Card(
            elevation: 0,
            color: const Color(0xFFF8F7FA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              title: Text(
                s.title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              children: [
                SelectableText(
                  s.body,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GuideSection {
  final String title;
  final String body;

  const _GuideSection({
    required this.title,
    required this.body,
  });
}
