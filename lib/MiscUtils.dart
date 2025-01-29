import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:geocoding/geocoding.dart';

class MiscUtil {
  // Image picker
  static Future<XFile?> pickImage({required ImageSource source}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    return pickedFile;
  }

  // dialog box
  static Future<void> showDialogBox(
      {required BuildContext context,
      required String title,
      required String message,
      String? positiveButtonText = 'OK',
      Function? onPositivePressed}) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            if (positiveButtonText != null && onPositivePressed != null)
              TextButton(
                onPressed: () {
                  onPositivePressed();

                  Navigator.of(context).pop();
                },
                child: Text(positiveButtonText),
              ),
          ],
        );
      },
    );
  }

  // Get current location
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Request permission to access location
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current location
    return await Geolocator.getCurrentPosition();
  }

// Get city and country from coordinates
  static Future<Map<String, String?>> getCityAndCountryFromCoordinates(
      double latitude, double longitude) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (placemarks.isNotEmpty) {
      return {
        'city': placemarks[0].locality,
        'country': placemarks[0].country,
      };
    } else {
      return {'city': null, 'country': null};
    }
  }

  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      return age - 1;
    } else {
      return age;
    }
  }
}
