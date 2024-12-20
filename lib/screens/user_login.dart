import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../reusable_widgets/widgets.dart';

class UserLoginPage extends StatefulWidget {
  @override
  _UserLoginPageState createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Function to handle login
  _login() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    try {
      // Log in the user with Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful")),
      );
      determineUserRole();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wrong Password or Email')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Future<void> determineUserRole() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String userId = currentUser.uid;

        // Check in `users` collection
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;
          bool isClinic = userData['isClinic'] ?? false;

          if (mounted) {
            Navigator.pushNamed(context, '/homepage');
          }
          return; // Exit function after handling `users`
        } else {
          // Check in `clinic` collection
          DocumentSnapshot clinicSnapshot = await FirebaseFirestore.instance
              .collection('clinic')
              .doc(userId)
              .get();

          if (clinicSnapshot.exists) {
            if (mounted) {
              Navigator.pushNamed(context, '/clinic_admin');
            }
          } else {
            print("User not found in both collections.");
          }
        }
      } else {
        print("No logged-in user.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wrong Password or Email')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Login"),
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            logoWidgetSmall('assets/banner.gif'),
            const SizedBox(
              height: 40,
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username / Email',
                errorText: _errorMessage,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _errorMessage,
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(), // Loading spinner
              ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 3,
              ),
              onPressed: _login,
              child: SizedBox(
                width: double.infinity, // Makes the button expand to full width
                child: Center(
                  child: Text('Login'), // Centers the text
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
