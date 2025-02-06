import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instadate/FirebaseService.dart';

class DateHandler {
  final FirebaseService _firebaseService = FirebaseService();

  /// **Apply for a Date and Sync Across 3 Locations**
  Future<void> applyForDate({
    required String dateId,
    required String applicantEmail,
    required String messageToCreator,
  }) async {
    try {
      print("📌 Applying for date: $dateId, Applicant: $applicantEmail");

      // **Step 1: Retrieve the Existing Date Data**
      Map<String, dynamic>? dateData = await getDateById(dateId);
      if (dateData == null) {
        print("❌ Date not found in 'dates' collection!");
        throw Exception("Date not found.");
      }

      String creatorEmail = dateData['email'] ?? '';
      if (creatorEmail.isEmpty) {
        print("❌ Error: Creator email is missing in the date entry.");
        throw Exception("Creator email is missing.");
      }

      // **Step 2: Add Applicant Data**
      dateData['applicants'] ??= {};
      dateData['applicants'][applicantEmail] = {
        'email': applicantEmail,
        'messageToCreator': messageToCreator,
        'messageToApplicant': '', // Creator fills this later
      };

      // **Step 3: Update All 3 Locations**
      await Future.wait([
        // Update Global `dates` Collection
        _firebaseService.uploadDataToFirestore(dateId, dateData, 'dates'),

        // Update Creator's `created_dates` Collection
        _firebaseService.uploadDataToFirestore(
            dateId, dateData, 'users/$creatorEmail/created_dates'),

        // Update Applicant's `applied_dates` Collection
        _firebaseService.uploadDataToFirestore(
            dateId, dateData, 'users/$applicantEmail/applied_dates'),
      ]);

      print("✅ Successfully applied for date: $dateId in all 3 locations!");
    } catch (e) {
      print("❌ Error applying for date: $e");
      throw e;
    }
  }

  Future<void> uploadDate({
    required String email,
    required Map<String, dynamic> dateData,
  }) async {
    try {
      // Generate a unique document ID for the date
      final String documentId =
          DateTime.now().millisecondsSinceEpoch.toString();

      print("📌 Step 1: Generated Document ID: $documentId");
      print("📌 Step 2: Received dateData: $dateData");

      // Ensure dateData is correctly formatted
      Map<String, dynamic> formattedData = dateData.map((key, value) {
        if (value is Timestamp) {
          return MapEntry(key, value.toDate()); // Convert Timestamp to DateTime
        }
        return MapEntry(key, value);
      });

      print("📌 Step 3: Formatted dateData: $formattedData");

      // Step 1: Store date in the global 'dates' collection
      print("📌 Step 4: Uploading to global 'dates' collection...");
      await _firebaseService.uploadDataToFirestore(
        documentId,
        {
          ...formattedData,
          'email': email, // Store the email as well
        },
        'dates', // Global collection
      );
      print("✅ Step 5: Successfully uploaded to 'dates' collection");

      // Step 2: Ensure the 'users/{email}' document exists
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(email);
      DocumentSnapshot userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        print("📌 Step 6: User document does not exist. Creating now...");
        await userDocRef
            .set({'createdAt': Timestamp.now()}); // Initialize document
        print("✅ Step 6.1: User document created");
      } else {
        print("✅ Step 6: User document already exists");
      }

      // Step 3: Store date in the user's personal 'created_dates' collection using set() instead of update()
      print(
          "📌 Step 7: Uploading to 'users/$email/created_dates' collection...");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('created_dates')
          .doc(documentId)
          .set(formattedData); // Use set() instead of update()

      print(
          "✅ Step 8: Successfully uploaded to 'users/$email/created_dates' collection");
    } catch (e, stackTrace) {
      print("❌ Error uploading date: $e");
      print("📌 Stack Trace: $stackTrace");
      throw e;
    }
  }

  /// **Accept an Applicant**
  Future<void> acceptApplicant({
    required String dateId,
    required String applicantEmail,
    required String messageToApplicant,
  }) async {
    try {
      print("📌 Accepting applicant: $applicantEmail for date: $dateId");

      // **Step 1: Retrieve the Existing Date Data**
      Map<String, dynamic>? dateData = await getDateById(dateId);
      if (dateData == null) {
        print("❌ Date not found in 'dates' collection!");
        throw Exception("Date not found.");
      }

      String creatorEmail = dateData['email'] ?? '';
      if (creatorEmail.isEmpty) {
        print("❌ Error: Creator email is missing in the date entry.");
        throw Exception("Creator email is missing.");
      }

      // **Step 2: Update `acceptedApplicant` and `messageToApplicant`**
      dateData['acceptedApplicant'] = applicantEmail;
      dateData['applicants'][applicantEmail]['messageToApplicant'] =
          messageToApplicant;

      // **Step 3: Update All 3 Locations**
      await Future.wait([
        // Update Global `dates` Collection
        _firebaseService.uploadDataToFirestore(dateId, dateData, 'dates'),

        // Update Creator's `created_dates` Collection
        _firebaseService.uploadDataToFirestore(
            dateId, dateData, 'users/$creatorEmail/created_dates'),

        // Update Applicant's `applied_dates` Collection
        _firebaseService.uploadDataToFirestore(
            dateId, dateData, 'users/$applicantEmail/applied_dates'),
      ]);

      print(
          "✅ Successfully accepted applicant: $applicantEmail in all 3 locations!");
    } catch (e) {
      print("❌ Error accepting applicant: $e");
      throw e;
    }
  }

  Future<void> deleteDate(String dateId) async {
    try {
      print("🗑️ Deleting date: $dateId");

      // Fetch date details to find creator and applicants
      Map<String, dynamic>? dateData = await getDateById(dateId);
      if (dateData == null) {
        print("⚠️ Date not found. Skipping deletion.");
        return;
      }

      String creatorEmail = dateData['email'] ?? '';
      Map<String, dynamic> applicants = dateData['applicants'] ?? {};

      // Step 1: Delete from `dates` collection (global)
      await FirebaseFirestore.instance.collection('dates').doc(dateId).delete();
      print("✅ Deleted from global 'dates' collection.");

      // Step 2: Delete from `users/{creatorEmail}/created_dates`
      await FirebaseFirestore.instance
          .collection('users')
          .doc(creatorEmail)
          .collection('created_dates')
          .doc(dateId)
          .delete();
      print("✅ Deleted from creator's 'created_dates' collection.");

      // Step 3: Delete from `users/{applicantEmail}/applied_dates`
      for (String applicantEmail in applicants.keys) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(applicantEmail)
            .collection('applied_dates')
            .doc(dateId)
            .delete();
        print("✅ Deleted from applicant's 'applied_dates': $applicantEmail");
      }

      print("✅ Date deleted successfully!");
    } catch (e) {
      print("❌ Error deleting date: $e");
      throw e;
    }
  }

  Future<Map<String, dynamic>?> getDateById(String documentId) async {
    try {
      print("📌 Fetching date data for document ID: $documentId...");

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('dates')
          .doc(documentId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        print("✅ Successfully retrieved date data: $data");
        return data;
      } else {
        print("⚠️ No date found with document ID: $documentId");
        return null;
      }
    } catch (e) {
      print("❌ Error retrieving date data: $e");
      return null;
    }
  }

  /// **Fetch Creator's Name Using Email**
  Future<String> getCreatorName(String email) async {
    try {
      print("🔍 Fetching creator name for email: $email");

      Map<String, dynamic>? userData =
          await _firebaseService.retrieveDataByDocId(email, 'users');

      if (userData != null && userData.containsKey('name')) {
        print("✅ Creator name found: ${userData['name']}");
        return userData['name'];
      } else {
        print("⚠️ Creator name not found, using default.");
        return "Date Creator";
      }
    } catch (e) {
      print("❌ Error fetching creator name: $e");
      return "Date Creator";
    }
  }
}
