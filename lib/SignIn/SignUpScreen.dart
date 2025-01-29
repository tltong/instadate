import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

import 'package:instadate/EmailAuthentication.dart';

import 'package:instadate/FirebaseService.dart';

import 'package:instadate/MiscUtils.dart'; // Import MiscUtils

import 'package:intl/intl.dart'; // Import for date formatting

import 'package:image_picker/image_picker.dart'; // Import for image picker

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKeyStep1 = GlobalKey<FormState>();

  final _formKeyStep2 = GlobalKey<FormState>();

  final _formKeyStep3 = GlobalKey<FormState>();

  final _formKeyStep4 = GlobalKey<FormState>(); // Key for Step 4

  final _nameController = TextEditingController();

  final _genderController = TextEditingController();

  final _occupationController = TextEditingController();

  final _descriptionController = TextEditingController();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final _emailAuth = EmailAuthentication();

  final _firebaseService = FirebaseService();

  int _currentStep = 0;

  DateTime _selectedDate = DateTime.now();

  String _selectedGender = 'Male'; // Default gender

  String? _selectedEducation; // For dropdown selection

  double _heightValue = 150; // Initial height value in cm

  Position? _userLocation; // To store the user's location

  String? _userCity;

  String? _userCountry;

  List<XFile?> _pickedImages = List.filled(3, null); // Store picked images

  List<String?> _imageUrls = List.filled(3, null); // Image URLs

  String? _selectedReligion; // For religion dropdown

  String? _selectedDatingPreference; // For dating preference dropdown

  @override
  void dispose() {
    _nameController.dispose();

    _genderController.dispose();

    _occupationController.dispose();

    _descriptionController.dispose();

    _emailController.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (step) {
          setState(() {
            _currentStep = step;
          });
        },
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            _submitForm();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          }
        },
        steps: [
          Step(
            title: const Text('Personal Details'),
            content: Form(
              key: _formKeyStep1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16.0),

                  Text('Gender:'), // Added text "Gender:"

                  Row(
                    children: [
                      Radio(
                        value: 'Male',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                      ),
                      const Text('Male'),
                      Radio(
                        value: 'Female',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                      ),
                      const Text('Female'),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Date of Birth: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _selectDate(context);
                        },
                        child: const Text('Select Date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('About Me'),
            content: Form(
              key: _formKeyStep2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedEducation,
                    decoration: const InputDecoration(
                      labelText: 'Education',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Bachelors',
                        child: Text('Bachelors'),
                      ),
                      DropdownMenuItem(
                        value: 'Masters',
                        child: Text('Masters'),
                      ),
                      DropdownMenuItem(
                        value: 'PhD',
                        child: Text('PhD'),
                      ),
                      DropdownMenuItem(
                        value: 'Others',
                        child: Text('Others'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedEducation = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your education';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: _occupationController,
                    decoration: const InputDecoration(
                      labelText: 'Occupation',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your occupation';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // Religion Dropdown

                  DropdownButtonFormField<String>(
                    value: _selectedReligion,
                    decoration: const InputDecoration(
                      labelText: 'Religion',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Buddhist',
                        child: Text('Buddhist'),
                      ),
                      DropdownMenuItem(
                        value: 'Christian',
                        child: Text('Christian'),
                      ),
                      DropdownMenuItem(
                        value: 'Muslim',
                        child: Text('Muslim'),
                      ),
                      DropdownMenuItem(
                        value: 'Hindu',
                        child: Text('Hindu'),
                      ),
                      DropdownMenuItem(
                        value: 'Jewish',
                        child: Text('Jewish'),
                      ),
                      DropdownMenuItem(
                        value: 'Non-Religious',
                        child: Text('Non-Religious'),
                      ),
                      DropdownMenuItem(
                        value: 'Others',
                        child: Text('Others'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedReligion = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your religion';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // Dating Preference Dropdown

                  DropdownButtonFormField<String>(
                    value: _selectedDatingPreference,
                    decoration: const InputDecoration(
                      labelText: 'Dating Preference',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Men',
                        child: Text('Men'),
                      ),
                      DropdownMenuItem(
                        value: 'Women',
                        child: Text('Women'),
                      ),
                      DropdownMenuItem(
                        value: 'Both',
                        child: Text('Both'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDatingPreference = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your dating preference';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16.0),

                  Text('Height (cm):'), // Added text for unit

                  Slider(
                    value: _heightValue,

                    min: 140, // Minimum height in cm

                    max: 210, // Maximum height in cm

                    divisions: 70, // Number of divisions for the slider

                    label: _heightValue.round().toString(),

                    onChanged: (value) {
                      setState(() {
                        _heightValue = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Describe Yourself',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please describe yourself';
                      }

                      return null;
                    },
                  ),

                  // Button to get user's location

                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // Get the user's location

                        final location = await MiscUtil.getCurrentLocation();

                        setState(() {
                          _userLocation = location;
                        });

                        // Get city and country using MiscUtil

                        final locationData =
                            await MiscUtil.getCityAndCountryFromCoordinates(
                          _userLocation!.latitude,
                          _userLocation!.longitude,
                        );

                        setState(() {
                          _userCity = locationData['city'];

                          _userCountry = locationData['country'];
                        });
                      } catch (e) {
                        // Handle errors

                        print('Error getting location: $e');

                        MiscUtil.showDialogBox(
                          context: context,
                          title: 'Error',
                          message:
                              'Failed to get your location. Please check your location settings.',
                        );
                      }
                    },
                    child: const Text('Get My Location'),
                  ),

                  // Display the user's location if available

                  if (_userCity != null && _userCountry != null)
                    Text(
                      'City: $_userCity, Country: $_userCountry',
                    ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Upload Images'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Upload Section

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Display the selected image as an icon

                          if (_pickedImages[i] != null)
                            CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  FileImage(File(_pickedImages[i]!.path)),
                            ),

                          // Show the "add photo" icon if no image is selected

                          if (_pickedImages[i] == null)
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            ),

                          // IconButton to pick an image

                          IconButton(
                            onPressed: () async {
                              XFile? pickedImage = await MiscUtil.pickImage(
                                  source: ImageSource.gallery);

                              if (pickedImage != null) {
                                setState(() {
                                  _pickedImages[i] =
                                      pickedImage; // Store the picked image
                                });
                              }
                            },
                            icon: Icon(
                              Icons.camera_alt,
                              size: 24,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Email & Password'),
            content: Form(
              key: _formKeyStep4, // Use the correct key for Step 4

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }

                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }

                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKeyStep4.currentState!.validate()) {
      // Validate Step 4

      final name = _nameController.text.trim();

      final gender = _selectedGender;

      final dateOfBirth = _selectedDate;

      final occupation = _occupationController.text.trim();

      final education = _selectedEducation!; // Get selected education

      final email = _emailController.text.trim();

      final password = _passwordController.text.trim();

      final heightCm = _heightValue; // Get height value from slider

      // Show the spinning circle

      showDialog(
        context: context,

        barrierDismissible: false, // Prevent dismissing by tapping outside

        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      try {
        final userCredential =
            await _emailAuth.createUserWithEmailAndPassword(email, password);

        if (userCredential != null) {
          _showSuccessDialog(context);

          // Upload images to Firebase Storage

          for (int i = 0; i < _pickedImages.length; i++) {
            if (_pickedImages[i] != null) {
              // Specify a custom storage path (optional)

              String? storagePath =
                  'user_images/${_emailController.text}/image_$i'; // Example

              String? downloadUrl = await _firebaseService
                  .uploadImage(_pickedImages[i]!, storagePath: storagePath);

              if (downloadUrl != null) {
                _imageUrls[i] = downloadUrl;
              }
            }
          }

          // Upload data to Firestore

          await _firebaseService.uploadDataToFirestore(
            email,
            {
              'name': name,

              'gender': gender,

              'dateOfBirth': dateOfBirth,

              'occupation': occupation,

              'education': education,

              'heightCm': heightCm, // Store height in cm

              'description': _descriptionController.text.trim(),

              'location': {
                'latitude': _userLocation?.latitude,
                'longitude': _userLocation?.longitude,
              },

              'images': _imageUrls, // Add the image URLs

              'religion': _selectedReligion, // Add the selected religion

              'datingPreference':
                  _selectedDatingPreference, // Add dating preference
            },
            'users',
          );

          // Dismiss the spinning circle after successful completion

          Navigator.of(context).pop(); // Dismiss the dialog

          Navigator.pushReplacementNamed(context, '/landing');
        } else {
          print('Error creating user');
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          _showAlertDialog(
              context, 'Weak Password', 'The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          _showAlertDialog(context, 'Email Exists',
              'The account already exists for that email.');
        }

        // Dismiss the spinning circle on error

        Navigator.of(context).pop(); // Dismiss the dialog
      }
    }
  }

  // Helper function to show a success dialog

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: const Text("User created successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Helper function to show an error dialog

  void _showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
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
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
