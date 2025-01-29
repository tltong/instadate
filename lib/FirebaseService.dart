import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseService {
  // Initialize Firebase and Firestore
  Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully!');

      // Initialize Firestore
      FirebaseFirestore.instance; // This line initializes Firestore
      print('Firestore initialized successfully!');
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  Future<void> uploadDataToFirestore(String documentId,
      Map<String, dynamic> data, String collectionName) async {
    try {
      print('Attempting to upload data to Firestore...');
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(documentId)
          .set(data);
      print('Data uploaded successfully to collection: $collectionName');
    } catch (e) {
      print('Error uploading data to Firestore: $e');
    }
  }

  /* usage :
  if key value is not empty - update DB
  if key value is an empty string - delete field in DB
  */

  Future<void> updateDataToFirestore(String documentId,
      Map<String, dynamic> data, String collectionName) async {
    try {
      // Create a map to store the updated data

      Map<String, dynamic> updatedData = {};

      // Iterate through the data map

      data.forEach((key, value) {
        // If the value is not an empty string, add it to the updatedData map

        if (value != '') {
          updatedData[key] = value;
        } else {
          // If the value is an empty string, delete the field

          FirebaseFirestore.instance
              .collection(collectionName)
              .doc(documentId)
              .update({key: FieldValue.delete()});
        }
      });

      // Update the document in Firestore (only if there are updates)

      if (updatedData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(documentId)
            .update(updatedData);

        print('Data updated successfully in collection: $collectionName');
      }
    } catch (e) {
      print('Error updating data in Firestore: $e');
    }
  }

  Future<Map<String, dynamic>?> retrieveDataByDocId(
      String documentId, String collectionName) async {
    try {
      print('Attempting to retrieve data from Firestore...');

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(documentId)
          .get();

      if (snapshot.exists) {
        print('Data retrieved successfully!');
        return snapshot.data() as Map<String, dynamic>;
      } else {
        print('Document with ID $documentId does not exist.');
        return null;
      }
    } catch (e) {
      print('Error retrieving data from Firestore: $e');
      return null;
    }
  }

  Future<String?> uploadImage(XFile imageFile, {String? storagePath}) async {
    if (imageFile != null) {
      try {
        // Create a reference to the storage location
        Reference storageReference = FirebaseStorage.instance.ref().child(
            storagePath ??
                'images/${DateTime.now().millisecondsSinceEpoch}'); // Use provided path or default

        // Upload the image
        UploadTask uploadTask = storageReference.putFile(File(imageFile.path));
        await uploadTask.whenComplete(() => print('Image uploaded'));
        // Get the download URL
        String downloadUrl = await storageReference.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        print('Error uploading image: ${e.toString()}');
        return null;
      }
    }
    return null;
  }

  Future<void> deleteFileFromStorage(String fileUrl) async {
    try {
      // Parse the file path from the URL
      //String filePath = Uri.parse(fileUrl).pathSegments.join('/');
      //String filePath = Uri.parse(fileUrl).path;
/*
      String filePath = fileUrl
          .split('/o/')[1] // Get the part after '/o/'
          .split('?')[0] // Remove query parameters
          .replaceAll('%40', '.') // Replace encoded '@' with '.'
          .replaceAll('%2F', '/'); // Decode forward slashes
*/

      String filePath = Uri.decodeComponent(
        fileUrl.split('/o/')[1].split(
            '?')[0], // Extract portion after '/o/' and remove query params
      );

      //print('======== FILEPATH from within FirebaseService: $filePath');
      // Create a reference to the file
      Reference storageReference = FirebaseStorage.instance.ref(filePath);

      // Check if the file exists
      try {
        await storageReference.getDownloadURL();
      } catch (e) {
        if (e is FirebaseException && e.code == 'object-not-found') {
          print('File not found, skipping deletion: $filePath');
          return;
        }
        rethrow; // Re-throw unexpected errors
      }

      // Delete the file
      await storageReference.delete();
      print('File deleted successfully: $filePath');
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
}
