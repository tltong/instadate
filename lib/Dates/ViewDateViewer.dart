import 'package:flutter/material.dart';
import 'package:instadate/Dates/DateHandler.dart';

class ViewDateViewer extends StatefulWidget {
  final Map<String, dynamic> dateData;
  final String dateId;
  final String applicantEmail;
  final String? creatorPhotoUrl; // ✅ Accept creator photo from ViewDate

  const ViewDateViewer({
    Key? key,
    required this.dateData,
    required this.dateId,
    required this.applicantEmail,
    this.creatorPhotoUrl, // ✅ Constructor receives photo
  }) : super(key: key);

  @override
  _ViewDateViewerState createState() => _ViewDateViewerState();
}

class _ViewDateViewerState extends State<ViewDateViewer> {
  final DateHandler _dateHandler = DateHandler();
  final TextEditingController _messageController = TextEditingController();
  bool hasApplied = false;

  @override
  void initState() {
    super.initState();
    hasApplied = (widget.dateData['applicants'] ?? {})
        .containsKey(widget.applicantEmail);
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
      await _dateHandler.applyForDate(
        dateId: widget.dateId,
        applicantEmail: widget.applicantEmail,
        messageToCreator: _messageController.text.trim(),
      );

      setState(() {
        hasApplied = true;
      });

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
    String creatorEmail = widget.dateData['email'];
    String? applicantMessage = widget.dateData['applicants']
        [widget.applicantEmail]?['messageToCreator'];
    String? creatorResponse = widget.dateData['applicants']
        [widget.applicantEmail]?['messageToApplicant'];
    String? acceptedApplicant = widget.dateData['acceptedApplicant'];
    String creatorName = widget.dateData['name'] ?? "Date Creator";
    String? creatorPhotoUrl = widget.creatorPhotoUrl; // ✅ Use passed photo URL

    print("📌 Building ViewDateViewer...");
    print("📌 Creator Email: $creatorEmail");
    print("📌 Applicant Email: ${widget.applicantEmail}");
    print("📸 Creator Image in Chat: $creatorPhotoUrl");

    /// **Determine Application Status**
    String applicationStatus;
    String statusMessage = "";
    Color statusColor = Colors.orange; // Default color for pending

    if (acceptedApplicant == null) {
      applicationStatus = "⏳ Pending Review";
      statusMessage = "Your application is under review.";
    } else if (acceptedApplicant == widget.applicantEmail) {
      applicationStatus = "🎉 Successful";
      statusMessage =
          "Congratulations! Remember to attend the date as planned. 📅";
      statusColor = Colors.green;
    } else {
      applicationStatus = "❌ Failed";
      statusMessage =
          "Unfortunately, another applicant was selected. Don't give up! Keep applying for other dates. 💪";
      statusColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("💬 Chat History",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // ✅ **Applicant's Message (Right Side)**
        if (applicantMessage != null && applicantMessage.trim().isNotEmpty)
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
                  child: Text(applicantMessage,
                      style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),

        // ✅ **Creator's Response (Left Side) with Profile Picture**
        if (creatorResponse != null && creatorResponse.trim().isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ **Show Creator's Photo in Chat**
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    creatorPhotoUrl != null && creatorPhotoUrl.isNotEmpty
                        ? NetworkImage(creatorPhotoUrl)
                        : null, // ✅ Show profile image if available
                backgroundColor: creatorPhotoUrl == null ? Colors.grey : null,
                child: creatorPhotoUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null, // Default icon if no image
              ),
              const SizedBox(width: 8),

              // **Chat Bubble**
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(creatorName,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(creatorResponse,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),

        const SizedBox(height: 16),

        // ✅ **Application Status Display**
        Center(
          child: Column(
            children: [
              Text(
                "📌 Application Status: $applicationStatus",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusMessage,
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

        // ✅ **Apply Button (If Not Already Applied)**
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
