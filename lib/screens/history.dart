import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'homepage.dart';

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
        isClinic = userSnapshot.data() != null && userSnapshot['isClinic'] == true;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
      ),
      body: appointmentHistory.isEmpty
          ? Center(child: Text('No appointment history available.'))
          : ListView.builder(
              itemCount: appointmentHistory.length,
              itemBuilder: (context, index) {
                if(isClinic) {
                  return ListTile(
                    title: Text(
                        '${appointmentHistory[index]['name']} - ${appointmentHistory[index]['appointment_date']}'),
                    subtitle:
                    Text('Status: Pending}'),
                  );
                }
                else{
                  return ListTile(
                    title: Text(
                        '${appointmentHistory[index]['clinicName']} - ${appointmentHistory[index]['appointment_date']}'),
                    subtitle:
                    Text('Status: "Pending'),
                  );
                }
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Log Out',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePage()),
              );
              break;
            case 2:
              Navigator.pushNamed(
                  context, '/');
                  _showLogOutDialog();
              break;
            default:
              break;
          }
        },
      ),
    );
  }
}
