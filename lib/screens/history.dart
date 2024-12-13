import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:vet_go/screens/homepage.dart';

import 'ProfilePage.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> appointmentHistory = [];
  int _currentIndex = 1;
  bool isClinic = false;

  @override
  void initState() {
    super.initState();
    //_fetchAppointmentHistory();
    fetchAppointmentsBasedOnRole();
  }

  Future<void> _fetchAppointmentHistory() async {
    final response = await http
        .get(Uri.parse('http://10.0.2.2/VETGO/fetch_appointments.php'));

    if (response.statusCode == 200) {
      List<dynamic> fetchedHistory = json.decode(response.body);
      setState(() {
        appointmentHistory = fetchedHistory
            .map((appointment) => Map<String, dynamic>.from(appointment))
            .toList();
      });
    } else {
      print("Failed to load appointment history: ${response.statusCode}");
    }
  }

  void _showLogOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log Out'),
          content: Text('Thank you for using Vetgo. Logged Out successfully!'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchAppointmentsBasedOnRole() async {
    // Get the current user
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Get the document ID of the current user
      String userDocId = currentUser.uid;

      // Check if the user is a clinic or not
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDocId)
          .get();

      if (userSnapshot.exists) {
        // Assuming the user has a role field (isClinic: true/false)
        isClinic =
            userSnapshot.data() != null && userSnapshot['isClinic'] == true;
        // Fetch appointments
        QuerySnapshot appointmentsSnapshot;

        if (isClinic) {
          // Query for clinics
          appointmentsSnapshot = await FirebaseFirestore.instance
              .collection('appointments')
              .where('clinic_id', isEqualTo: userDocId)
              .get();
        } else {
          // Query for users
          appointmentsSnapshot = await FirebaseFirestore.instance
              .collection('appointments')
              .where('userid', isEqualTo: userDocId)
              .get();
        }

        // Print the results
        if (appointmentsSnapshot.docs.isNotEmpty) {
          setState(() {
            appointmentHistory = appointmentsSnapshot.docs
                .map((doc) => Map<String, dynamic>.from(doc.data() as Map))
                .toList();
          });
        } else {
          print("No appointments found for this user/clinic.");
        }
      } else {
        print("User does not exist in the database.");
      }
    } else {
      print("No user is logged in.");
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool isExitingApp = await _showExitConfirmation(context);
        return isExitingApp;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromRGBO(184, 225, 241, 1),
          elevation: 4,
        ),
        body: appointmentHistory.isEmpty
            ? const Center(
          child: Text(
            'No appointment history available.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        )
            : ListView.separated(
          itemCount: appointmentHistory.length,
          separatorBuilder: (context, index) => const Divider(
            thickness: 1,
            height: 1,
            color: Colors.grey,
          ),
          itemBuilder: (context, index) {
            final appointment = appointmentHistory[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    isClinic
                        ? appointment['name']?.substring(0, 1) ?? ''
                        : appointment['clinicName']?.substring(0, 1) ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  isClinic
                      ? '${appointment['name']} - ${appointment['appointment_date']}'
                      : '${appointment['clinicName']} - ${appointment['appointment_date']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Status: ${appointment['status']}',
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  // Handle item tap if necessary
                },
              ),
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Color.fromRGBO(184, 225, 241, 1),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
      onTap: _handleBottomNavigation,
    );
  }

  void _handleBottomNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryPage(),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(),
          ),
        );
        break;
    }
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Exit App?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text('Are you sure you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  child: Text('exit', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
