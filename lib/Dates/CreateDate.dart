import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateDate extends StatefulWidget {
  final String email;

  const CreateDate({Key? key, required this.email}) : super(key: key);

  @override
  _CreateDateState createState() => _CreateDateState();
}

class _CreateDateState extends State<CreateDate> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _description;
  String? _selectedDuration;
  String? _selectedWhoPays;
  String? _selectedOpenTo;
  String? _selectedDateType;
  LatLng? _selectedLatLng;
  String? _googleMapsUrl; // Store the Google Maps URL
  final TextEditingController _locationController = TextEditingController();
  List<Map<String, dynamic>> _locationSuggestions = [];
  Timer? _debounce;

  final String _googleApiKey =
      "AIzaSyAz5wgFHrAJ7ZxVHg6EBwtLGMg1NqsMlkc"; // Replace with your API key

  @override
  void dispose() {
    _locationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Date')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Date Type'), // New section for "Date Type"

            const SizedBox(height: 8.0),

            DropdownButton<String>(
              value: _selectedDateType,
              hint: const Text('Select Date Type'),
              items: <String>[
                'Coffee',
                'Lunch',
                'Dinner',
                'Movie',
                'Casual Hangout',
                'Wine and Music',
                'Active',
                'Cultural',
                'Exhibition',
                'Others',
                'Getaway',
                'Extra Special',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDateType = newValue;
                });
              },
            ),

            const SizedBox(height: 16.0),
            const Text('Date and Time'),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: Text(_selectedDate != null
                        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                        : 'Select Date'),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectTime(context),
                    child: Text(_selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Select Time'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text('Duration'),
            const SizedBox(height: 8.0),
            DropdownButton<String>(
              value: _selectedDuration,
              hint: const Text('Select Duration'),
              items: <String>[
                '< 1 hour',
                '1 hour',
                '2 hours',
                '3 hours',
                '4 hours or more',
                'Let\'s go with the flow',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDuration = newValue;
                });
              },
            ),
            const SizedBox(height: 16.0),

            const Text('Who Pays'), // New section for "Who Pays"

            const SizedBox(height: 8.0),

            DropdownButton<String>(
              value: _selectedWhoPays,
              hint: const Text('Select Who Pays'),
              items: <String>[
                'I pay',
                'You pay',
                'Let\'s split',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedWhoPays = newValue;
                });
              },
            ),

            const SizedBox(height: 16.0),

            const Text('Date is open to'), // New section for "Date is open to"

            const SizedBox(height: 8.0),

            DropdownButton<String>(
              value: _selectedOpenTo,
              hint: const Text('Select Open To'),
              items: <String>[
                'Men',
                'Women',
                'Men and Women',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedOpenTo = newValue;
                });
              },
            ),

            const SizedBox(height: 16.0),
            const Text('Description'),
            const SizedBox(height: 8.0),
            TextField(
              onChanged: (value) => setState(() => _description = value),
              decoration:
                  const InputDecoration(hintText: 'Enter a description'),
            ),
            const SizedBox(height: 16.0),
            const Text('Location'),
            const SizedBox(height: 8.0),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Search for a location',
                border:
                    OutlineInputBorder(), // Optional: Adds a border for better UI
              ),
              maxLines: null, // Allows multiple lines
              keyboardType: TextInputType.multiline, // Enables multi-line input
              onChanged: _getLocationSuggestions,
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                itemCount: _locationSuggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_locationSuggestions[index]['description']),
                    onTap: () => _selectLocation(_locationSuggestions[index]),
                  );
                },
              ),
            ),
            if (_googleMapsUrl != null) ...[
              const SizedBox(height: 8.0),
              GestureDetector(
                onTap: () => _openGoogleMaps(_googleMapsUrl!),
                child: Text(
                  "Open in Google Maps",
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ],
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _saveDateToFirestore,
              child: const Text('Create Date'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _getLocationSuggestions(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _locationSuggestions = []);
        return;
      }

      try {
        final response = await Dio().get(
          "https://maps.googleapis.com/maps/api/place/autocomplete/json",
          queryParameters: {
            "input": query,
            "key": _googleApiKey,
            "components": "country:my", // Filter by country (MY = Malaysia)
          },
        );

        if (response.statusCode == 200) {
          List predictions = response.data["predictions"];
          setState(() {
            _locationSuggestions = predictions
                .map((p) => {
                      "description": p["description"],
                      "place_id": p["place_id"],
                    })
                .toList();
          });
        }
      } catch (e) {
        print("Error fetching location suggestions: $e");
      }
    });
  }

  Future<void> _selectLocation(Map<String, dynamic> selectedLocation) async {
    String locationName = selectedLocation["description"];
    _locationController.text = locationName;
    setState(() => _locationSuggestions = []);

    try {
      final response = await Dio().get(
        "https://maps.googleapis.com/maps/api/place/details/json",
        queryParameters: {
          "place_id": selectedLocation["place_id"],
          "key": _googleApiKey,
        },
      );

      if (response.statusCode == 200) {
        var location = response.data["result"]["geometry"]["location"];
        double lat = location["lat"];
        double lng = location["lng"];

        setState(() {
          _selectedLatLng = LatLng(lat, lng);
          _googleMapsUrl =
              "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(locationName)}";
        });
      }
    } catch (e) {
      print("Error fetching location details: $e");
    }
  }

  void _openGoogleMaps(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("Could not open Google Maps");
    }
  }

  Future<void> _saveDateToFirestore() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _description == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    DateTime finalDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.email)
        .collection('dates')
        .doc();

    await docRef.set({
      'date': Timestamp.fromDate(finalDateTime),
      'description': _description,
      'location': _locationController.text,
      'latitude': _selectedLatLng?.latitude,
      'longitude': _selectedLatLng?.longitude,
      'duration': _selectedDuration,
      'whoPays': _selectedWhoPays,
      'openTo': _selectedOpenTo,
    });

    Navigator.pop(context);
  }
}
