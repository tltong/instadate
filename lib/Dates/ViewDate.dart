import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✅ Import for date formatting
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instadate/Dates/ViewDateViewer.dart';
import 'package:instadate/Dates/ViewDateCreator.dart';
import 'package:instadate/Dates/DateHandler.dart';

class ViewDate extends StatefulWidget {
  final String dateId;
  final String applicantEmail;

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
  Map<String, dynamic>? creatorProfile;

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
      });

      // Fetch Creator's Full Profile
      _fetchCreatorProfile();
    } else {
      print("⚠️ No data found for Date ID: ${widget.dateId}");
    }
  }

  /// **Fetch Creator's Full Profile**
  Future<void> _fetchCreatorProfile() async {
    if (creatorEmail == null) return;

    print("🔍 Fetching full creator profile for email: $creatorEmail");

    Map<String, dynamic> profile =
        await _dateHandler.getCreatorInfo(creatorEmail!);

    // Extract profile picture correctly
    String? photoUrl;
    if (profile.containsKey('images') &&
        profile['images'] is List &&
        profile['images'].isNotEmpty) {
      photoUrl = profile['images'][0]; // ✅ Get the first image
    }

    setState(() {
      creatorProfile = {
        ...profile,
        'photoUrl': photoUrl, // ✅ Ensure profile contains photoUrl
      };
    });

    print("📛 Loaded Creator Name: ${creatorProfile?['name']}");
    print("📸 Loaded Creator Image URL: ${creatorProfile?['photoUrl']}");
  }

  /// **Navigate to Creator's Profile Page via Named Route**
  void _openProfilePage() {
    if (creatorProfile == null) return;

    Navigator.pushNamed(context, '/profile', arguments: creatorProfile);
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
              // ✅ **Creator Info (Name & Profile Picture) - Clickable**
              GestureDetector(
                onTap: _openProfilePage,
                child: Row(
                  children: [
                    if (creatorProfile?['photoUrl'] != null &&
                        creatorProfile!['photoUrl'].isNotEmpty)
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            NetworkImage(creatorProfile!['photoUrl']),
                      )
                    else
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        child:
                            Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Date Host: ${creatorProfile?['name'] ?? "Unknown"}",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ✅ **Display Date Details**
              _buildDateDetail("📅 Date Type", dateData!['dateType']),
              _buildDateDetail("📅 Date",
                  _formatDate(dateData!['date'])), // ✅ Format date properly
              _buildDateDetail("🕒 Time", dateData!['time']),
              _buildDateDetail("📍 Location", dateData!['location']),
              _buildEnhancedWhoPays(
                  dateData!['whoPays']), // ✅ Enhanced 'Who Pays'
              _buildDateDetail("📝 Description",
                  dateData!['description']), // ✅ Show Date Description
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

              // ✅ **Show Viewer or Creator UI**
              isCreator
                  ? ViewDateCreator(dateData: dateData!, dateId: widget.dateId)
                  : ViewDateViewer(
                      dateData: dateData!,
                      dateId: widget.dateId,
                      applicantEmail: widget.applicantEmail,
                      creatorPhotoUrl: creatorProfile?['photoUrl'],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Reusable Widget to Display Date Details**
  Widget _buildDateDetail(String title, dynamic value) {
    if (value == null || value.toString().trim().isEmpty)
      return const SizedBox(); // Hide if empty

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text("$title: $value",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
    );
  }

  /// **Format Firestore Timestamp to Readable Date**
  String _formatDate(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return DateFormat('EEE, MMM d, yyyy').format(dateValue.toDate());
    }
    return dateValue.toString();
  }

  /// **Enhanced Who Pays Display**
  Widget _buildEnhancedWhoPays(String? whoPays) {
    String displayText;

    if (whoPays == "I pay") {
      displayText = "I pay, you just come along!";
    } else if (whoPays == "You pay") {
      displayText = "You pay, I like to be pampered!";
    } else {
      displayText = whoPays ?? "N/A";
    }

    return _buildDateDetail("💰 Who Pays", displayText);
  }
}
