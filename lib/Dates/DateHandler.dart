import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instadate/FirebaseService.dart';

class DateHandler {
  final FirebaseService _firebaseService = FirebaseService();

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

      // Step 3: Store date in the user's personal 'user_dates' collection using set() instead of update()
      print("📌 Step 7: Uploading to 'users/$email/user_dates' collection...");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('user_dates')
          .doc(documentId)
          .set(formattedData); // Use set() instead of update()

      print(
          "✅ Step 8: Successfully uploaded to 'users/$email/user_dates' collection");
    } catch (e, stackTrace) {
      print("❌ Error uploading date: $e");
      print("📌 Stack Trace: $stackTrace");
      throw e;
    }
  }
}
