import 'package:flutter/material.dart';
import 'package:instadate/Dates/DateHandler.dart';

class ViewDateCreator extends StatefulWidget {
  final Map<String, dynamic> dateData;
  final String dateId;

  const ViewDateCreator({
    Key? key,
    required this.dateData,
    required this.dateId,
  }) : super(key: key);

  @override
  _ViewDateCreatorState createState() => _ViewDateCreatorState();
}

class _ViewDateCreatorState extends State<ViewDateCreator> {
  final DateHandler _dateHandler = DateHandler();
  final Map<String, TextEditingController> _applicantMessages = {};

  @override
  void initState() {
    super.initState();
    widget.dateData['applicants']?.forEach((email, _) {
      _applicantMessages[email] = TextEditingController();
    });
  }

  /// **Accept an Applicant**
  Future<void> _acceptApplicant(String applicantEmail) async {
    String message = _applicantMessages[applicantEmail]?.text.trim() ?? "";

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a message before accepting.')),
      );
      return;
    }

    try {
      await _dateHandler.acceptApplicant(
        dateId: widget.dateId,
        applicantEmail: applicantEmail,
        messageToApplicant: message,
      );

      setState(() {
        widget.dateData['acceptedApplicant'] = applicantEmail;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application from $applicantEmail accepted!')),
      );
    } catch (e) {
      print("❌ Error accepting applicant: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("👤 Applicants:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...widget.dateData['applicants'].entries.map((entry) {
          String email = entry.key;
          return Card(
            child: ListTile(
              title: Text(email),
              trailing: ElevatedButton(
                onPressed: () => _acceptApplicant(email),
                child: const Text("Accept"),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
