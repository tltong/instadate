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
  String? _googleMapsUrl;
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown(
                    "Date Type",
                    _selectedDateType,
                    [
                      'Coffee',
                      'Lunch',
                      'Dinner',
                      'Movie',
                      'Casual Hangout',
                      'Wine and Music',
                      'Active',
                      'Cultural',
                      'Others',
                      'Getaway',
                      'Extra Special',
                    ],
                    (value) => setState(() => _selectedDateType = value)),

                const SizedBox(height: 16.0),
                _buildDateAndTimePicker(),

                _buildDropdown(
                    "Duration",
                    _selectedDuration,
                    [
                      '1 hour',
                      '2 hours',
                      '3 hours',
                      '4 hours or more',
                      'Let\'s go with the flow',
                    ],
                    (value) => setState(() => _selectedDuration = value)),

                _buildDropdown(
                    "Who Pays",
                    _selectedWhoPays,
                    [
                      'I pay',
                      'You pay',
                      'Let\'s split',
                    ],
                    (value) => setState(() => _selectedWhoPays = value)),

                _buildDropdown(
                    "Date is Open To",
                    _selectedOpenTo,
                    [
                      'Men',
                      'Women',
                      'Men and Women',
                    ],
                    (value) => setState(() => _selectedOpenTo = value)),

                _buildTextField("Description", _description, (value) {
                  setState(() => _description = value);
                }),

                const SizedBox(height: 16.0),
                const Text('Location'),
                const SizedBox(height: 8.0),

                // Multi-line Location Input
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'Search for a location',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  onChanged: _getLocationSuggestions,
                ),

                if (_googleMapsUrl != null) ...[
                  const SizedBox(height: 8.0),
                  GestureDetector(
                    onTap: () => _openGoogleMaps(_googleMapsUrl!),
                    child: Text(
                      "📍 View Location on Google Maps",
                      style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],

                const SizedBox(height: 8.0),
                _buildLocationSuggestions(),

                const SizedBox(height: 32.0),
                ElevatedButton(
                  onPressed: _saveDateToFirestore,
                  child: const Text('Create Date'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String title, String? selectedValue, List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8.0),
        DropdownButton<String>(
          value: selectedValue,
          hint: Text('Select $title'),
          items: items.map((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateAndTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildTextField(
      String title, String? value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8.0),
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(hintText: 'Enter $title'),
        ),
      ],
    );
  }

  Widget _buildLocationSuggestions() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _locationSuggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_locationSuggestions[index]['description']),
            onTap: () => _selectLocation(_locationSuggestions[index]),
          );
        },
      ),
    );
  }

  void _openGoogleMaps(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("Could not open Google Maps");
    }
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

  Future<void> _saveDateToFirestore() async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.email)
        .collection('dates')
        .doc();

    await docRef.set({
      'date': Timestamp.fromDate(_selectedDate!),
      'description': _description,
      'location': _locationController.text,
      'latitude': _selectedLatLng?.latitude,
      'longitude': _selectedLatLng?.longitude,
      'duration': _selectedDuration,
      'whoPays': _selectedWhoPays,
      'openTo': _selectedOpenTo,
      'dateType': _selectedDateType,
    });

    Navigator.pop(context);
  }
}
