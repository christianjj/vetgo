import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        SnackBar(content: Text("Login Successful")),
      );
      Navigator.pushNamed(context, '/homepage');
      // Navigate to the home screen or another screen after login
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => HomeScreen()), // Replace with your HomeScreen
      // );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Wrong Email or Password")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
    // if (username.isEmpty || password.isEmpty) {
    //   setState(() {
    //     _errorMessage = 'Please enter both username/email and password';
    //   });
    //   return;
    // }
    //
    // final url = Uri.parse('http://10.0.2.2/VETGO/api.php');
    // final response = await http.post(url, body: {
    //   'username': username,
    //   'password': password,
    // });
    //
    // print('Response status: ${response.statusCode}');
    // print('Response body: ${response.body}');
    //
    // if (response.statusCode == 200) {
    //   final responseData = json.decode(response.body);
    //
    //   if (responseData['user_exists'] == true) {
    //     Navigator.pushNamed(context, '/homepage');
    //   } else if (responseData['admin_exists'] == true) {
    //     Navigator.pushNamed(context, '/admin_home');
    //   } else if (responseData['clinic_admin_exists'] == true) {
    //     Navigator.pushNamed(context, '/clinic_admin');
    //   } else {
    //     setState(() {
    //       _errorMessage =
    //           responseData['error'] ?? 'Invalid username/email or password';
    //     });
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Login"),
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username / Email',
                errorText: _errorMessage,
              ),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _errorMessage,
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            if (_isLoading)
              Container(
                color: Colors.transparent, // Semi-transparent background
                child: Center(
                  child: CircularProgressIndicator(), // Loading spinner
                ),
              ),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
