import 'package:flutter/material.dart';
import 'package:instadate/Dates/DateHandler.dart';

class ViewDate extends StatefulWidget {
  final String dateId; // Firestore document ID of the date
  final String applicantEmail; // Email of the person viewing the page

  const ViewDate({
    Key? key,
    required this.dateId,
    required this.applicantEmail,
  }) : super(key: key);

  @override
  _ViewDateState createState() => _ViewDateState();
}

class _ViewDateState extends State<ViewDate> {
  final DateHandler _dateHandler = DateHandler();
  Map<String, dynamic>? dateData;
  String? creatorEmail;

  bool isCreator = false;
  bool hasApplied = false;
  final TextEditingController _messageController = TextEditingController();
  final Map<String, TextEditingController> _applicantMessages =
      {}; // Stores messages for each applicant

  @override
  void initState() {
    super.initState();
    _fetchDateData();
  }

  /// **Fetch Date Data from Firestore via DateHandler**
  Future<void> _fetchDateData() async {
    print("🔍 Fetching date details for ID: ${widget.dateId}");

    Map<String, dynamic>? data = await _dateHandler.getDateById(widget.dateId);

    if (data != null) {
      print("✅ Date data retrieved: $data");

      setState(() {
        dateData = data;
        creatorEmail = data['email'];
        isCreator = widget.applicantEmail == creatorEmail;
        hasApplied =
            (data['applicants'] ?? {}).containsKey(widget.applicantEmail);

        if (isCreator) {
          data['applicants']?.forEach((email, _) {
            _applicantMessages[email] = TextEditingController();
          });
        }
      });
    } else {
      print("⚠️ No data found for Date ID: ${widget.dateId}");
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
        dateData!['acceptedApplicant'] = applicantEmail;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application from $applicantEmail accepted!')),
      );
    } catch (e) {
      print("❌ Error accepting applicant: $e");
    }
  }

  /// **Delete the Date**
  Future<void> _deleteDate() async {
    if (!isCreator) return; // Ensure only creator can delete

    try {
      await _dateHandler.deleteDate(widget.dateId);
      Navigator.pop(context); // Close page after deletion
    } catch (e) {
      print("❌ Error deleting date: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting date. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dateData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("View Date")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateDetail("📅 Date Type", dateData!['dateType']),
              _buildDateDetail("🕒 Time", dateData!['time']),
              _buildDateDetail("📍 Location", dateData!['location']),
              _buildDateDetail("💰 Who Pays", dateData!['whoPays']),
              _buildDateDetail("👥 Open To", dateData!['openTo']),
              _buildDateDetail("✅ Accepted Applicant",
                  dateData!['acceptedApplicant'] ?? "None"),
              const SizedBox(height: 16),
              if (dateData!['googleMapsUrl'] != null &&
                  dateData!['googleMapsUrl'].toString().isNotEmpty)
                GestureDetector(
                  onTap: () {
                    print(
                        "🔗 Opening Google Maps URL: ${dateData!['googleMapsUrl']}");
                  },
                  child: Text(
                    "📍 View Location on Google Maps",
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              isCreator ? _buildCreatorUI() : _buildViewerUI(),
              if (isCreator)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: _deleteDate,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("🗑️ Delete Date",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Reusable Widget to Display Date Details**
  Widget _buildDateDetail(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text("$title: ${value ?? 'N/A'}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
    );
  }

  /// **UI for Creators (View & Accept Applicants)**
  Widget _buildCreatorUI() {
    Map<String, dynamic> applicants = dateData!['applicants'] ?? {};
    String? acceptedApplicant = dateData!['acceptedApplicant'];

    return applicants.isEmpty
        ? const Center(child: Text("No one has applied yet."))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("👤 Applicants:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...applicants.entries.map((entry) {
                String email = entry.key;
                bool isAccepted = email == acceptedApplicant;
                bool isAnotherAccepted =
                    acceptedApplicant != null && !isAccepted;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  color: isAccepted
                      ? Colors.green[100]
                      : Colors.white, // Highlight accepted applicant
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAccepted ? Colors.green : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _applicantMessages[email],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Message to applicant...",
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: isAccepted || isAnotherAccepted
                              ? null
                              : () => _acceptApplicant(email),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAccepted ? Colors.green : null,
                          ),
                          child: Text(
                              isAccepted ? "✅ Accepted" : "Accept Applicant"),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
  }

  /// **UI for Viewers (Applicants) - Chat History & Status**
  Widget _buildViewerUI() {
    print("📌 Building Viewer UI...");

    // Fetch messages
    String? applicantMessage =
        dateData!['applicants'][widget.applicantEmail]?['messageToCreator'];
    String? creatorResponse =
        dateData!['applicants'][widget.applicantEmail]?['messageToApplicant'];
    String? acceptedApplicant = dateData!['acceptedApplicant'];
    String creatorEmail = dateData!['email'] ?? "";

    // Default creator name
    String creatorName = "Date Creator";

    // Retrieve Creator's Name from Firestore
    if (dateData!.containsKey('name')) {
      creatorName = dateData!['name'];
    }

    // Determine Application Status
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

        // Applicant's Message (Right Side)
        if (applicantMessage != null)
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(applicantMessage,
                      style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),

        // Creator's Response (Left Side) with Registered Name
        if (creatorResponse != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
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
          ),

        const SizedBox(height: 16),

        // Status of Application
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

        // Apply Button (If Not Already Applied)
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
