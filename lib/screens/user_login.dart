import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserLoginPage extends StatefulWidget {
  @override
  _UserLoginPageState createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;

  // Function to handle login
  Future<void> _login() async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username/email and password';
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2/VETGO/api.php');
    final response = await http.post(url, body: {
      'username': username,
      'password': password,
    });

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['user_exists'] == true) {
        Navigator.pushNamed(context, '/homepage');
      } else if (responseData['admin_exists'] == true) {
        Navigator.pushNamed(context, '/admin_home');
      } else if (responseData['clinic_admin_exists'] == true) {
        Navigator.pushNamed(context, '/clinic_admin');
      } else {
        setState(() {
          _errorMessage =
              responseData['error'] ?? 'Invalid username/email or password';
        });
      }
    }
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
