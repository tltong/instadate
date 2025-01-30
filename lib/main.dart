import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:instadate/FirebaseService.dart';
import 'package:instadate/SignIn/SignUpScreen.dart';
import 'package:instadate/Landing/LandingPage.dart';
import 'package:instadate/Profile/ProfilePage.dart'; // Import ProfilePage
import 'package:instadate/Profile/EditProfilePage.dart'; // Import EditProfilePage
import 'package:instadate/SignIn/SignInScreen.dart'; // Import SignInScreen
import 'package:instadate/Dates/CreateDate.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensures Flutter framework is initialized before Firebase
  await Firebase.initializeApp(); // Initialize Firebase
  await FirebaseService().initializeFirebase(); // Initialize Firestore

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
  final _emailController = TextEditingController();
  Map<String, dynamic>? _userData;

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
            // TEST Firestore DB
            ElevatedButton(
              onPressed: () async {
                Map<String, dynamic> myData = {
                  'name': 'John Doe',
                  'age': 30,
                  'city': 'New York',
                };
                await _firebaseService.uploadDataToFirestore(
                    "docID", myData, 'users');
              },
              child: const Text('Test Firestore DB'),
            ),

            // TEST Email sign up and user data upload
            ElevatedButton(
              onPressed: () async {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text('Test Email sign up'),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Email',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      String email = _emailController.text.trim();

                      if (email.isNotEmpty) {
                        //full
                        // print(email);
                        // _userData = await _firebaseService.retrieveDataByDocId(
                        //   email, 'users');
                        // print('Name: ${_userData?['name']}');
                        //if (_userData != null) {
                        // Navigator.pushNamed(context, '/profile',
                        //     arguments: _userData);       }

                        //minimal
                        Map<String, dynamic> userData = {'email': email};
                        userData = (await _firebaseService.retrieveDataByDocId(
                            email, 'users'))!;
                        if (userData != null) {
                          Navigator.pushNamed(context, '/profile',
                              arguments: userData);
                        } else {
                          // Handle case where user data is not found

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User not found'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Get User Info'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      String email = _emailController.text.trim();

                      if (email.isNotEmpty) {
                        Map<String, dynamic> userData = {'email': email};

                        userData = (await _firebaseService.retrieveDataByDocId(
                            email, 'users'))!;

                        if (userData != null) {
                          userData['email'] = email;

                          Navigator.pushNamed(context, '/editprofile',
                              arguments: userData);
                        } else {
                          // Handle case where user data is not found

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User not found'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Edit Profile'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signin');
                    },
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      String email = _emailController.text.trim();

                      if (email.isNotEmpty) {
                        Navigator.pushNamed(context, '/createdate',
                            arguments: email); // Pass email as argument
                      }
                    },
                    child: const Text('Create Date'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
