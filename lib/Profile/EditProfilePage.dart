import 'dart:io';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instadate/FirebaseService.dart'; // Import FirebaseService
import 'package:instadate/MiscUtils.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService =
      FirebaseService(); // FirebaseService instance

  // Controllers for text fields
  final _occupationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _heightController = TextEditingController(); // Controller for height

  // Selected value for education dropdown
  String? _selectedEducation;
  String? _selectedReligion;
  String? _calculatedAge;
  String? _userCity;
  String? _userCountry;
  Position? _userLocation; // Store the user's location

  Map<String, dynamic> _originalUserData = {};
  List<String> _displayImages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize controllers with existing data
    _occupationController.text = widget.userData['occupation'] ?? '';
    _selectedEducation = widget.userData['education'];
    _selectedReligion = widget.userData['religion'];
    _heightController.text =
        widget.userData['heightCm']?.toString() ?? ''; // Initialize height
    _descriptionController.text =
        widget.userData['description'] ?? ''; // Initialize description

    if (widget.userData['dateOfBirth'] != null) {
      DateTime birthDate = widget.userData['dateOfBirth'].toDate();
      int age = MiscUtil.calculateAge(birthDate);
      _calculatedAge = age.toString();
    }
    if (widget.userData['location'] != null &&
        widget.userData['location']['latitude'] != null &&
        widget.userData['location']['longitude'] != null) {
      _fetchCityAndCountry();
    }

    _originalUserData = Map.from(widget.userData);
    _displayImages = List<String>.from(widget.userData['images'] ?? []);

    while (_displayImages.length < 3) {
      _displayImages.add(''); // Add empty strings as placeholders
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _occupationController.dispose();
    _descriptionController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _fetchCityAndCountry() async {
    final latitude = widget.userData['location']['latitude'];
    final longitude = widget.userData['location']['longitude'];

    final locationData =
        await MiscUtil.getCityAndCountryFromCoordinates(latitude, longitude);

    setState(() {
      _userCity = locationData['city'];
      _userCountry = locationData['country'];
    });
  }

  Future<void> _refreshLocation() async {
    try {
      // Get the user's location

      final location = await MiscUtil.getCurrentLocation();

      // Update the userLocation state

      setState(() {
        _userLocation = location;
      });

      // Get city and country using MiscUtil

      final locationData = await MiscUtil.getCityAndCountryFromCoordinates(
        location.latitude,
        location.longitude,
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
  }

// Function to delete a photo (only from the tab)
  Future<void> _deletePhoto(int index) async {
    // Count how many non-empty photos exist
    int nonEmptyPhotos =
        _displayImages.where((image) => image.isNotEmpty).length;

    // 🚨 Prevent deletion if only one photo remains
    if (nonEmptyPhotos <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must have at least one profile photo.')),
      );
      return;
    }

    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Photo?'),
          content: const Text('Are you sure you want to delete this photo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Close dialog, don't delete
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Close dialog, confirm delete
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        _displayImages[index] = ''; // Remove photo, keep placeholder
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo removed from display.')),
      );
    }
  }

  // Function to replace a photo (only in the tab)
  Future<void> _replacePhoto(int index) async {
    // Use MiscUtil.pickImage to select a new photo

    XFile? newImage = await MiscUtil.pickImage(source: ImageSource.gallery);

    if (newImage != null) {
      // Replace the photo in the list

      setState(() {
        _displayImages[index] = newImage.path; // Store the new image path
      });

      // Show a success message

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo replaced')),
      );
    }
  }

// Function to upload a new photo (only in the tab)

  Future<void> _uploadPhoto(int index) async {
    // Use MiscUtil.pickImage to select a new photo

    XFile? newImage = await MiscUtil.pickImage(source: ImageSource.gallery);

    if (newImage != null) {
      // Add the new photo to the list (using the image path)

      setState(() {
        _displayImages[index] = newImage.path;
      });

      // Show a success message

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded')),
      );
    }
  }

  bool _isLoading = false; // Track if an operation is in progress

  Future<void> _saveChanges() async {
    if (_isLoading) return; // Prevent multiple clicks

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    List<String> oldImages =
        List<String>.from(_originalUserData['images'] ?? []);
    List<String> newImageUrls = List<String>.from(_displayImages);

    // Remove empty placeholders before comparing
    newImageUrls.removeWhere((image) => image.isEmpty);

    // 🚨 Check if there are NO CHANGES before proceeding
    if (listEquals(oldImages, newImageUrls)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes made to profile photos.')),
      );
      setState(() {
        _isLoading = false; // Hide spinner
      });
      return; // Exit function early
    }

    bool photosChanged = false;

    // Step 1: Check if any new photos were added
    for (int i = 0; i < _displayImages.length; i++) {
      if (_displayImages[i].isNotEmpty &&
          !_displayImages[i].startsWith('http')) {
        photosChanged = true;
        break;
      }
    }

    // Step 2: Upload new images if necessary
    if (photosChanged) {
      newImageUrls.clear(); // Reset list and repopulate

      for (int i = 0; i < _displayImages.length; i++) {
        if (_displayImages[i].isNotEmpty &&
            !_displayImages[i].startsWith('http')) {
          try {
            String storagePath =
                'user_images/${widget.userData['email']}/image_${DateTime.now().millisecondsSinceEpoch}';

            // Upload new image
            String? imageUrl = await _firebaseService.uploadImage(
              XFile(_displayImages[i]),
              storagePath: storagePath,
            );

            if (imageUrl != null) {
              newImageUrls.add(imageUrl);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload image at slot $i.')),
              );
              setState(() {
                _isLoading = false; // Hide spinner
              });
              return;
            }
          } catch (e) {
            print('Error uploading image $i: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error uploading image at slot $i: $e')),
            );
            setState(() {
              _isLoading = false; // Hide spinner
            });
            return;
          }
        } else if (_displayImages[i].isNotEmpty) {
          newImageUrls.add(_displayImages[i]); // Keep existing URLs
        }
      }
    }

    // Step 3: Delete old images that are no longer in the new list
    for (String oldImage in oldImages) {
      if (oldImage.isNotEmpty && !newImageUrls.contains(oldImage)) {
        try {
          await _firebaseService.deleteFileFromStorage(oldImage);
        } catch (e) {
          print('Error deleting old photo: $e');
        }
      }
    }

    // Step 4: Ensure `_displayImages` always has 3 slots (with placeholders for empty ones)
    while (newImageUrls.length < 3) {
      newImageUrls.add(''); // Add empty slots as placeholders
    }

    // Step 5: Update Firestore with the new image list
    try {
      await _firebaseService.updateDataToFirestore(
        widget.userData['email'],
        {'images': newImageUrls},
        'users',
      );

      // ✅ Ensure both `_originalUserData['images']` and `_displayImages` are updated
      setState(() {
        _originalUserData['images'] = List<String>.from(newImageUrls);
        _displayImages = List<String>.from(newImageUrls); // Maintain 3 slots
        _isLoading = false; // Hide spinner
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      print('Error updating Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
      setState(() {
        _isLoading = false; // Hide spinner
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(widget.userData['images'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Photos'),
            Tab(text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Photos Tab

          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Images as Icons

                  if (_displayImages.isNotEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100, // Adjust height as needed

                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _displayImages.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  // Show a dialog with options to delete or replace

                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Photo Options'),
                                        content: const Text(
                                            'What would you like to do with this photo?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close dialog
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close dialog

                                              _deletePhoto(index);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close dialog

                                              _replacePhoto(index);
                                            },
                                            child: const Text('Replace'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: _displayImages[index].isEmpty
                                      ? IconButton(
                                          onPressed: () {
                                            _uploadPhoto(index);
                                          },
                                          icon: const Icon(Icons.add_a_photo),
                                        )
                                      : CircleAvatar(
                                          radius: 40, // Adjust radius as needed

                                          backgroundImage: _displayImages[index]
                                                  .startsWith('http')
                                              ? NetworkImage(
                                                  _displayImages[index])
                                              : FileImage(
                                                  File(_displayImages[index])),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _saveChanges, // Disable button when loading
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ),

          // Info Tab
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description Field
                  TextFormField(
                    controller: _descriptionController,

                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),

                    maxLines: 3, // Allow multiple lines
                  ),
                  const SizedBox(height: 20),

                  // Height Field
                  TextFormField(
                    controller: _heightController,
                    keyboardType:
                        TextInputType.number, // Set keyboard type to number
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                    ),
                  ),

                  const SizedBox(height: 20),

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
                  ),

                  const SizedBox(height: 20),

                  // Occupation Field
                  TextFormField(
                    controller: _occupationController,
                    decoration: const InputDecoration(
                      labelText: 'Occupation',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Education Dropdown
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
                  ),
                  const SizedBox(height: 20),

                  if (widget.userData['location'] != null &&
                      widget.userData['location']['latitude'] != null &&
                      widget.userData['location']['longitude'] != null)
                    GestureDetector(
                      onTap: () {
                        // Show a dialog to ask if the user wants to refresh location

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Refresh Location?'),
                              content: const Text(
                                  'Do you want to update your location?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();

                                    _refreshLocation();
                                  },
                                  child: const Text('Refresh'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          FutureBuilder<Map<String, String?>>(
                            future: MiscUtil.getCityAndCountryFromCoordinates(
                                widget.userData['location']['latitude'],
                                widget.userData['location']['longitude']),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  'Location: ${snapshot.data!['city']}, ${snapshot.data!['country']}',
                                  style: const TextStyle(fontSize: 16),
                                );
                              } else {
                                return const CircularProgressIndicator();
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Save Button
                  ElevatedButton(
                    onPressed: () async {
                      Map<String, dynamic> updatedData = {};
                      if (_selectedEducation !=
                          _originalUserData['education']) {
                        updatedData['education'] = _selectedEducation;
                      }
                      if (_occupationController.text !=
                          _originalUserData['occupation']) {
                        updatedData['occupation'] = _occupationController.text;
                      }
                      if (_selectedReligion != _originalUserData['religion']) {
                        updatedData['religion'] = _selectedReligion;
                      }
                      if (_descriptionController.text !=
                          _originalUserData['description']) {
                        updatedData['description'] =
                            _descriptionController.text;
                      }
                      if (int.tryParse(_heightController.text) !=
                          _originalUserData['heightCm']) {
                        updatedData['heightCm'] =
                            int.tryParse(_heightController.text) ?? 0;
                      }
                      if (_userLocation != null) {
                        updatedData['location'] = {
                          'latitude': _userLocation!.latitude,
                          'longitude': _userLocation!.longitude,
                        };
                      }
                      if (updatedData.isNotEmpty) {
                        await _firebaseService.updateDataToFirestore(
                            widget.userData['email'], updatedData, 'users');

                        // Show a success message or navigate back

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated')),
                        );
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                  const SizedBox(height: 20),

                  // Non-Editable Information Section
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.lock),
                      const SizedBox(width: 8),
                      Text(
                        'Name: ${widget.userData['name'] ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (widget.userData['dateOfBirth'] != null)
                    Row(
                      children: [
                        const Icon(Icons.lock),
                        const SizedBox(width: 8),
                        Text(
                          'Age: $_calculatedAge',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.lock),
                      const SizedBox(width: 8),
                      Text(
                        'Gender: ${widget.userData['gender'] ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.lock),
                      const SizedBox(width: 8),
                      Text(
                        'Email: ${widget.userData['email'] ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.lock),
                      const SizedBox(width: 8),
                      Text(
                        'Dating Preference: ${widget.userData['datingPreference'] ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
