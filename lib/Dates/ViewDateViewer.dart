import 'package:flutter/material.dart';
import 'package:instadate/Dates/DateHandler.dart';

class ViewDateViewer extends StatefulWidget {
  final Map<String, dynamic> dateData;
  final String dateId;
  final String applicantEmail;
  final String? creatorPhotoUrl;
  final String? creatorName;

  const ViewDateViewer({
    Key? key,
    required this.dateData,
    required this.dateId,
    required this.applicantEmail,
    this.creatorPhotoUrl,
    this.creatorName,
  }) : super(key: key);

  @override
  _ViewDateViewerState createState() => _ViewDateViewerState();
}

class _ViewDateViewerState extends State<ViewDateViewer> {
  final DateHandler _dateHandler = DateHandler();
  final TextEditingController _messageController = TextEditingController();
  bool hasApplied = false;
  bool hasChatHistory = false;

  @override
  void initState() {
    super.initState();
    print("📌 [ViewDateViewer] - Initializing...");
    print("📌 [ViewDateViewer] - Received dateData: ${widget.dateData}");

    Map<String, dynamic>? applicants = widget.dateData['applicants'];
    if (applicants != null) {
      hasApplied = applicants.containsKey(widget.applicantEmail);
      print("📌 [ViewDateViewer] - Applicants found: $applicants");

      String? applicantMessage =
          applicants[widget.applicantEmail]?['messageToCreator'];
      String? creatorResponse =
          applicants[widget.applicantEmail]?['messageToApplicant'];

      hasChatHistory =
          (applicantMessage != null && applicantMessage.trim().isNotEmpty) ||
              (creatorResponse != null && creatorResponse.trim().isNotEmpty);

      print("📌 [ViewDateViewer] - Applicant's Message: $applicantMessage");
      print("📌 [ViewDateViewer] - Creator's Response: $creatorResponse");
      print("📌 [ViewDateViewer] - Chat History Exists: $hasChatHistory");
    } else {
      print("⚠️ [ViewDateViewer] - No applicants data found.");
    }

    print("📌 [ViewDateViewer] - hasApplied: $hasApplied");

    if (!hasChatHistory) {
      print(
          "📌 [ViewDateViewer] - No Chat History Found. Skipping chat section.");
    }
  }

  /// **Apply for the Date**
  Future<void> _applyForDate() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a message before applying.')),
      );
      return;
    }

    try {
      print(
          "📌 Applying for Date: ${widget.dateId}, Applicant: ${widget.applicantEmail}");

      await _dateHandler.applyForDate(
        dateId: widget.dateId,
        applicantEmail: widget.applicantEmail,
        messageToCreator: _messageController.text.trim(),
      );

      setState(() {
        hasApplied = true;
      });

      print("✅ Successfully applied for the date!");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You have successfully applied for this date!')),
      );
    } catch (e) {
      print("❌ Error applying for date: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🛠️ [ViewDateViewer] - Building UI...");

    String creatorEmail = widget.dateData['email'] ?? "Unknown";
    Map<String, dynamic>? applicants = widget.dateData['applicants'];

    String creatorName = widget.creatorName ?? "Date Creator";
    String? creatorPhotoUrl = widget.creatorPhotoUrl;
    String? acceptedApplicant = widget.dateData['acceptedApplicant'];

    print("📌 [ViewDateViewer] - Creator Email: $creatorEmail");
    print("📌 [ViewDateViewer] - Current User Email: ${widget.applicantEmail}");
    print("📌 [ViewDateViewer] - Accepted Applicant: $acceptedApplicant");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasChatHistory) ...[
          const Text("💬 Chat History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (applicants?[widget.applicantEmail]?['messageToCreator'] != null)
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("You",
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        color: Colors.blue[200],
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                        applicants![widget.applicantEmail]['messageToCreator'],
                        style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          if (applicants?[widget.applicantEmail]?['messageToApplicant'] != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      creatorPhotoUrl != null && creatorPhotoUrl.isNotEmpty
                          ? NetworkImage(creatorPhotoUrl)
                          : null,
                  backgroundColor: creatorPhotoUrl == null ? Colors.grey : null,
                  child: creatorPhotoUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(creatorName,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                          applicants![widget.applicantEmail]
                              ['messageToApplicant'],
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),
        ],
        Center(
          child: Column(
            children: [
              Text(
                acceptedApplicant == widget.applicantEmail
                    ? "🎉 Successful"
                    : acceptedApplicant == null
                        ? "⏳ Pending Review"
                        : "❌ Failed",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: acceptedApplicant == widget.applicantEmail
                      ? Colors.green
                      : acceptedApplicant == null
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                acceptedApplicant == widget.applicantEmail
                    ? "Congratulations! Remember to attend the date as planned. 📅"
                    : acceptedApplicant == null
                        ? "Your application is under review."
                        : "Unfortunately, another applicant was selected. Keep applying for other dates. 💪",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!hasApplied)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("💌 Send a message to the date creator:"),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Write your message...",
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _applyForDate,
                child: const Text("📩 Apply for Date"),
              ),
            ],
          ),
      ],
    );
  }
}
