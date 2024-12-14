import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'DisplayImageCached.dart';
import 'logoutDialog.dart';

class vetProfilePage extends StatefulWidget {
  @override
  _vetProfilePageState createState() => _vetProfilePageState();
}

class _vetProfilePageState extends State<vetProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _userProfile = {};
  Map<String, String> _uploadedFiles = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
        await _firestore.collection('clinic').doc(currentUser.uid).get();

        setState(() {
          _userProfile = userDoc.data() as Map<String, dynamic>;
          _uploadedFiles = Map<String, String>.from(_userProfile['uploaded_files'] ?? {});
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load profile information');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Color.fromRGBO(184, 225, 241, 1)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : 'Not provided',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedFileItem(String label, String fileUrl) {
    bool isImage = fileUrl.endsWith('.png') ||
        fileUrl.endsWith('.jpg') ||
        fileUrl.endsWith('.jpeg');

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, color: Colors.blue),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                if (isImage)
                  Image.network(
                    fileUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                else
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayImageCached(imageUrl: fileUrl),
                        ),
                      );
                    },
                    child: const Text(
                      'View File',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              LogoutDialog.showLogoutDialog(context, () {
                _auth.signOut();
                Navigator.pushNamed(context, '/');
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Color.fromRGBO(184, 225, 241, 1),
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '${_userProfile['clinicName'] ?? ''}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            _buildProfileItem(
              icon: Icons.email,
              label: 'Owner',
              value: _userProfile['ownerName'] ?? '',
            ),
            _buildProfileItem(
              icon: Icons.home,
              label: 'Address',
              value: _userProfile['clinicAddress'] ?? '',
            ),
            SizedBox(height: 24),
            Text(
              'Uploaded Files',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ..._uploadedFiles.entries.map((entry) {
              return _buildUploadedFileItem(entry.key, entry.value);
            }).toList(),
          ],
        ),
      ),
    );
  }
}
