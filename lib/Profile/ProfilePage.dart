import 'package:flutter/material.dart';
import 'package:instadate/MiscUtils.dart'; // Import MiscUtils
import 'package:intl/intl.dart'; // Import for date formatting

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 0; // Track the current photo index
  late PageController _pageController; // PageController to control the PageView

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(widget.userData['images'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Images using PageView
              if (images.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: images.length,
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () async {
                              final selectedIndex = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullImageScreen(
                                    images: images,
                                    initialIndex: _currentIndex,
                                  ),
                                ),
                              );
                              if (selectedIndex != null) {
                                setState(() {
                                  _currentIndex = selectedIndex;
                                  _pageController.jumpToPage(_currentIndex);
                                });
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                images[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Display photo numbering
                    Text(
                      '${_currentIndex + 1}/${images.length}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // Display Name
              if (widget.userData['name'] != null)
                Text(
                  widget.userData['name'],
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 10),

              // Calculate and Display Age
              if (widget.userData['dateOfBirth'] != null)
                FutureBuilder<int>(
                  future: calculateAge(widget.userData['dateOfBirth']
                      .toDate()), // Convert to DateTime
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        '${snapshot.data} years old',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              const SizedBox(height: 10),

              // Display Location
              if (widget.userData['location'] != null &&
                  widget.userData['location']['latitude'] != null &&
                  widget.userData['location']['longitude'] != null)
                FutureBuilder<Map<String, String?>>(
                  future: MiscUtil.getCityAndCountryFromCoordinates(
                      widget.userData['location']['latitude'],
                      widget.userData['location']['longitude']),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        '${snapshot.data!['city']}, ${snapshot.data!['country']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              const SizedBox(height: 10),

              const SizedBox(height: 20), // Added extra line

              // Display Description
              if (widget.userData['description'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About me:',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.userData['description'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20), // Added extra line
                  ],
                ),

              // Display Height
              if (widget.userData['heightCm'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Height:',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${widget.userData['heightCm']} cm',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20), // Added extra line
                  ],
                ),

              // Display Religion
              if (widget.userData['religion'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Religion:',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.userData['religion'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20), // Added extra line
                  ],
                ),

              // Display Occupation
              if (widget.userData['occupation'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Occupation:',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.userData['occupation'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20), // Added extra line
                  ],
                ),

              // Display Education
              if (widget.userData['education'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Education:',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.userData['education'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to calculate age
  Future<int> calculateAge(DateTime birthDate) async {
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

class FullImageScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullImageScreen({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _FullImageScreenState createState() => _FullImageScreenState();
}

class _FullImageScreenState extends State<FullImageScreen> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context,
                _currentIndex); // Return the current index to the ProfilePage
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: PageView.builder(
          itemCount: widget.images.length,
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(0),
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            );
          },
        ),
      ),
    );
  }
}
