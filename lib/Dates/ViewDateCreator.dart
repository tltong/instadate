import 'package:flutter/material.dart';
import 'package:instadate/Dates/DateHandler.dart';
import 'package:instadate/Profile/ProfilePage.dart';

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
  final Map<String, Map<String, dynamic>> _applicantDetails = {};

  bool hasApplicants = false;
  String? acceptedApplicant;

  @override
  void initState() {
    super.initState();

    print("📌 [ViewDateCreator] - Initializing...");
    print("📌 [ViewDateCreator] - Received dateData: ${widget.dateData}");

    Map<String, dynamic>? applicants = widget.dateData['applicants'];
    acceptedApplicant = widget.dateData['acceptedApplicant'];

    if (applicants != null && applicants.isNotEmpty) {
      hasApplicants = true;
      print("📌 [ViewDateCreator] - Applicants found: $applicants");

      applicants.forEach((email, data) {
        _applicantMessages[email] = TextEditingController();
        _fetchApplicantDetails(email);
      });
    } else {
      print("⚠️ [ViewDateCreator] - No applicants yet.");
    }
  }

  /// **Fetch Applicant's Full Profile from Firestore**
  Future<void> _fetchApplicantDetails(String email) async {
    print("🔍 Fetching applicant details for: $email");

    Map<String, dynamic> userInfo = await _dateHandler.getUserInfo(email);

    setState(() {
      _applicantDetails[email] = userInfo;
    });

    print("✅ [ViewDateCreator] - Fetched: ${_applicantDetails[email]}");
  }

  /// **Navigate to Applicant's Profile Page**
  void _openProfilePage(String email) {
    if (_applicantDetails[email] == null) {
      print("⚠️ [ViewDateCreator] - Applicant profile not available.");
      return;
    }

    print("🔍 Navigating to ProfilePage for: $email");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userData: _applicantDetails[email]!),
      ),
    );
  }

  /// **Accept an Applicant**
  Future<void> _acceptApplicant(String applicantEmail) async {
    if (acceptedApplicant != null) {
      print(
          "⚠️ [ViewDateCreator] - Applicant already accepted: $acceptedApplicant");
      return;
    }

    String message = _applicantMessages[applicantEmail]?.text.trim() ?? "";

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a message before accepting.')),
      );
      return;
    }

    try {
      print(
          "📌 Accepting Applicant: $applicantEmail for Date: ${widget.dateId}");

      await _dateHandler.acceptApplicant(
        dateId: widget.dateId,
        applicantEmail: applicantEmail,
        messageToApplicant: message,
      );

      setState(() {
        acceptedApplicant = applicantEmail;
        widget.dateData['acceptedApplicant'] = applicantEmail;
      });

      print("✅ Successfully accepted applicant: $applicantEmail!");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application from $applicantEmail accepted!')),
      );
      await _refreshDateData();
    } catch (e) {
      print("❌ Error accepting applicant: $e");
    }
  }

  Future<void> _refreshDateData() async {
    print("🔄 Refreshing date data for ID: ${widget.dateId}...");

    try {
      Map<String, dynamic>? updatedDateData =
          await _dateHandler.getDateById(widget.dateId);

      if (updatedDateData != null) {
        setState(() {
          widget.dateData.clear();
          widget.dateData.addAll(updatedDateData);
          acceptedApplicant = updatedDateData['acceptedApplicant'];
        });
        print("✅ Date data refreshed successfully!");
      } else {
        print("⚠️ Failed to refresh date data.");
      }
    } catch (e) {
      print("❌ Error refreshing date data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🛠️ [ViewDateCreator] - Building UI...");

    if (!hasApplicants) {
      return const Center(child: Text("No applicants yet. Check back later."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("👤 Applicants:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...widget.dateData['applicants'].entries.map((entry) {
          String email = entry.key;
          String? applicantMessage = entry.value['messageToCreator'];
          String? creatorResponse = entry.value['messageToApplicant'];
          bool isAccepted = email == acceptedApplicant;
          bool disableOtherButtons = acceptedApplicant != null;

          String applicantName = _applicantDetails[email]?['name'] ?? email;
          List<String> applicantImages =
              List<String>.from(_applicantDetails[email]?['images'] ?? []);
          String? applicantPhotoUrl =
              applicantImages.isNotEmpty ? applicantImages[0] : null;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ **Applicant Info (Clickable Avatar & Name)**
                  GestureDetector(
                    onTap: () => _openProfilePage(email),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: applicantPhotoUrl != null
                              ? NetworkImage(applicantPhotoUrl)
                              : null,
                          backgroundColor:
                              applicantPhotoUrl == null ? Colors.grey : null,
                          child: applicantPhotoUrl == null
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(applicantName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ **Chat History**
                  if (applicantMessage != null &&
                      applicantMessage.trim().isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("📩 Applicant's Message:",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(applicantMessage,
                                style: const TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),

                  if (creatorResponse != null &&
                      creatorResponse.trim().isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("📤 Your Response:",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                                color: Colors.blue[200],
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(creatorResponse,
                                style: const TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ✅ **Accept Button**
                  isAccepted
                      ? const Text("✅ Accepted",
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold))
                      : ElevatedButton(
                          onPressed: disableOtherButtons
                              ? null
                              : () => _acceptApplicant(email),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                disableOtherButtons ? Colors.grey : null,
                          ),
                          child: const Text("Accept"),
                        ),

                  // ✅ **Reply TextField**
                  if (!isAccepted)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: _applicantMessages[email],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Reply to Applicant",
                        ),
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
