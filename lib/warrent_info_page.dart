import 'package:flutter/material.dart';

class WarrantInfoPage extends StatelessWidget {
  const WarrantInfoPage({super.key});

  // The UI of the warrant info page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warrant Info')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'GUIDANCE FOR LEOs',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'FOUND TAG - DO THIS FIRST!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'DO THIS FIRST WHEN AN ILLICIT TAG IS FOUND\n'
            '1. Process the found tag for fingerprints and DNA before handling!\n\n'
            '2. For an AirTag:\n'
            '\t\ta. Process the inside of the Airtag and its lithium battery for prints and DNA.\n'
            '\t\tb. Using gloves, hold the AirTag over a place that is fall safe.\n'
            '\t\tc. Squeeze it flat between the palms and rotate the silver side counterclockwise slightly until the silver cover becomes loose.\n'
            '\t\td. Zoom in to photograph the serial number of the Airtag and ensure the photo is easy to read before fingerprinting.\n'
            '\t\te. Then, carefully process the inside of the battery cover, both sides of the battery, and the plastic side of the battery compartment for fingerprints and DNA.\n'
            '\t\tf. Offenders often remove the speaker on the printed circuit board, so carefully pry off the underside of the battery holder (Note: it is not difficult for an offender to swap this cover to mislead you just like a switched vin on a car - so include your LeoFindIt scan results to include the UUID and Mac address with date and time observed in your preservation request and warrant.',
          ),
          SizedBox(height: 24),
          Text(
            'FOUND APPLE AIRTAG',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          SelectableText(
            'FOR APPLE AIRTAGS (25 Days Retention)\n'
            '1. FIRST, complete DO THIS FIRST, above, to process for prints and DNA.\n\n'
            '2. Submit a preservation request ASAP, found here - no cost to your agency - https://www.apple.com/legal/privacy/gle-inforequest.pdf.\n\n'
            '3. On the form under the Information Supporting Request copy and paste the following and complete all blanks:\n\n'
            '“AirTag Serial Number: ____________________________\n'
            'UUID on LeoFindIt: ____________________________________\n'
            'MAC on LeoFIndIt: ____________________________________\n'
            'Date UUID/MAC was scanned: ____________________\n'
            'Time UUID/MAC was scanned: ___________________ Time Zone: ____________\n'
            'Location where tag was found (address or gps coordinates): ______________________”\n\n'
            '4. On the form under the Information Requested from Apple, copy and paste the following:\n\n'
            '“Apple is requested to preserve the following records and information until receiving a judicial search warrant which is in process. The warrant will include a nondisclosure order and I request Apple withhold any notification to the customer until the warrant is served on Apple:\n\n'
            '\t\ta. Paired Account Details related to the found AirTag or Find My bluetooth tag identified in the Information Supporting Request section above, including username, email address, iCloud username/email address, phone number, and any personalized tag name.\n'
            '\t\tb. All customer information for the “paired account,” including current and former:\n'
            '\t\tc. names of the paired account holder, billing addresses, shipping addresses, phone numbers (even if not assigned to an associated Apple device), email addresses issued by or external to Apple, and locations of Apple Stores where purchases were made under “Paired Account”\n'
            '\t\td. iMessaging phone numbers/usernames/email addresses for the Paired Account\n'
            '\t\te. Identifiers including names and email address of associated accounts that exist under or above the Paired Account (such as Family iCloud members or former members)\n'
            '\t\tf. login and connection metadata to include date/time, IP address, city/state/country, and browser used for access by the “paired account.”\n'
            '\t\tg. Identifiers for each device associated with the “paired account” including every: AirTag, Find My device, MacOS device, iOS device, WatchOS device, Mac computer, iPhone, iPad, and Apple Watch:\n'
            '\t\t\t\t• Device serial number assigned by Apple, including all IMEIs for cellular devices,\n'
            '\t\t\t\t• All sim, e-sim, or nano sim numbers,\n'
            '\t\t\t\t• All phone numbers assigned to a device and the name of the cellular carrier,\n'
            '\t\t\t\t• Date added to the paired account,\n'
            '\t\t\h. Find My Connection Logs for every device on the paired account,\n'
            '\t\ti. Find My transactional activity for requests marking any device as lost, or to remotely lock, send a sound to, or to erase a device, including the text of the recovery message sent to the device by the “paired account.”\n'
            '\t\tj. For the specific AirTag and/or FindMy found in this investigation - the device listed under Information Supporting Request on the paired account:\n'
            '\t\t\t\t• The UUID and MAC address assigned by Apple on the date and time indicated.\n'
            '\t\t\t\t• Identify the phone numbers and iCloud email addresses for each of the iOS devices Apple sent an alert to for an “unknown AirTag/Find My device traveling with them” and include the mapped tracking data provided to them regarding the AirTag or Find My device prompting this request.”\n\n'
            '5. Without delay, send the request form, the photo of the tag serial number, and a screenshot from LeoFindIt with the UUID and MAC from your agency email address to LAWENFORCEMENT@APPLE.COM. Waiting for a followup unit to submit the form is a precious loss of evidence in the case.\n\n'
            '6. Consider sending the form, without personal info, to feedback@leofindit.com so the programming team at Florida Gulf Coast University can receive input on the success of the LeoFindIt application.\n\n'
            '7. Include your form with the case report which should be attached to the warrant. You can also include the report from the LeoFindIt application. The search warrant MUST contain the same exact bullets as the preservation request. Serve the warrant to the same email address, at no cost to the government. It should specify the time frame of the search warrant as the day you emailed the preservation request, to present.\n\n'
            '8. IMPORTANT: Apple will promptly notify the suspect about the request from law enforcement unless you serve a NONDISCLOSURE order signed by the court when you obtain the warrant. Please inform the followup unit if someone else will be obtaining the warrant.',
          ),
        ],
      ),
    );
  }
}
