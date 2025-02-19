import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instadate/FirebaseService.dart';
import 'package:instadate/SignIn/SignUpScreen.dart';
import 'package:instadate/Landing/LandingPage.dart';
import 'package:instadate/Profile/ProfilePage.dart';
import 'package:instadate/Profile/EditProfilePage.dart';
import 'package:instadate/SignIn/SignInScreen.dart';
import 'package:instadate/Dates/CreateDate.dart';
import 'package:instadate/Dates/ViewDate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseService().initializeFirebase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter DEMO',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
      routes: {
        '/signup': (context) => SignUpScreen(),
        '/landing': (context) => LandingPage(),
        '/profile': (context) => ProfilePage(
              userData: ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>,
            ),
        '/editprofile': (context) => EditProfilePage(
              userData: ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>,
            ),
        '/signin': (context) => SignInScreen(),
        '/createdate': (context) => CreateDate(
              email: ModalRoute.of(context)!.settings.arguments as String,
            ),
        '/viewdate': (context) => ViewDate(
              dateId: (ModalRoute.of(context)!.settings.arguments
                  as Map<String, String>)['dateId']!,
              applicantEmail: (ModalRoute.of(context)!.settings.arguments
                  as Map<String, String>)['applicantEmail']!,
            ),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseService _firebaseService = FirebaseService();

  List<String> _userEmails = [];
  List<String> _dateIds = [];
  String? _selectedEmail;
  String? _selectedDateId;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchDateIds();
  }

  /// **Fetch all user emails from Firestore**
  Future<void> _fetchUsers() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      List<String> emails = snapshot.docs
          .map((doc) => doc.id)
          .toList(); // Firestore doc ID is the email
      setState(() {
        _userEmails = emails;
      });
    } catch (e) {
      print("❌ Error fetching users: $e");
    }
  }

  /// **Fetch all Date IDs from Firestore**
  Future<void> _fetchDateIds() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('dates').get();
      List<String> dateIds = snapshot.docs
          .map((doc) => doc.id)
          .toList(); // Firestore doc ID is the Date ID
      setState(() {
        _dateIds = dateIds;
      });
    } catch (e) {
      print("❌ Error fetching dates: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text('Test Email Sign Up'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // **Dropdown for Email Selection**
                  DropdownButtonFormField<String>(
                    value: _selectedEmail,
                    items: _userEmails.map((email) {
                      return DropdownMenuItem(
                        value: email,
                        child: Text(email),
                      );
                    }).toList(),
                    onChanged: (email) {
                      setState(() {
                        _selectedEmail = email;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Email',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_selectedEmail != null) {
                        Map<String, dynamic>? userData = await _firebaseService
                            .retrieveDataByDocId(_selectedEmail!, 'users');

                        if (userData != null) {
                          Navigator.pushNamed(context, '/profile',
                              arguments: userData);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User not found')),
                          );
                        }
                      }
                    },
                    child: const Text('Get User Info'),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_selectedEmail != null) {
                        Map<String, dynamic>? userData = await _firebaseService
                            .retrieveDataByDocId(_selectedEmail!, 'users');

                        if (userData != null) {
                          userData['email'] = _selectedEmail;
                          Navigator.pushNamed(context, '/editprofile',
                              arguments: userData);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User not found')),
                          );
                        }
                      }
                    },
                    child: const Text('Edit Profile'),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedEmail != null) {
                        Navigator.pushNamed(context, '/createdate',
                            arguments: _selectedEmail);
                      }
                    },
                    child: const Text('Create Date'),
                  ),

                  const SizedBox(height: 30),

                  // **Dropdown for Date ID Selection**
                  DropdownButtonFormField<String>(
                    value: _selectedDateId,
                    items: _dateIds.map((dateId) {
                      return DropdownMenuItem(
                        value: dateId,
                        child: Text(dateId),
                      );
                    }).toList(),
                    onChanged: (dateId) {
                      setState(() {
                        _selectedDateId = dateId;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Date ID',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // **Button to View Date**
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedEmail != null && _selectedDateId != null) {
                        Navigator.pushNamed(context, '/viewdate', arguments: {
                          'dateId': _selectedDateId!,
                          'applicantEmail': _selectedEmail!,
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please select an Email and a Date ID')),
                        );
                      }
                    },
                    child: const Text('View Date'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
