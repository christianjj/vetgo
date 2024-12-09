import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'homepage.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  List<Map<String, dynamic>> appointments = [];

  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final response = await http
        .get(Uri.parse('http://10.0.2.2/VETGO/fetch_appointments.php'));

    if (response.statusCode == 200) {
      List<dynamic> fetchedAppointments = json.decode(response.body);
      setState(() {
        appointments = fetchedAppointments
            .where((appointment) => appointment['status'] == 'Pending')
            .map((appointment) => Map<String, dynamic>.from(appointment))
            .toList();
      });
    } else {
      print("Failed to load appointments: ${response.statusCode}");
    }
  }

  Future<void> _updateAppointmentStatus(
      int appointmentId, String status) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/VETGO/update_appointment_status.php'),
      body: {
        'appointment_id': appointmentId.toString(),
        'status': status,
      },
    );

    if (response.statusCode == 200) {
      print('Status updated successfully: $status');
    } else {
      print('Failed to update status: ${response.statusCode}');
    }
  }

  void _approveAppointment(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Approval'),
          content: Text('Are you sure you want to approve this appointment?'),
          actions: [
            TextButton(
              onPressed: () async {
                int appointmentId =
                    int.tryParse(appointments[index]['id'].toString()) ?? 0;
                await _updateAppointmentStatus(appointmentId, 'Approved');
                setState(() {
                  appointments[index]['status'] =
                      'Approved';
                });
                Navigator.of(context).pop();
              },
              child: Text('Approve'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _rejectAppointment(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Rejection'),
          content: Text('Are you sure you want to reject this appointment?'),
          actions: [
            TextButton(
              onPressed: () async {
                await _updateAppointmentStatus(
                    appointments[index]['id'], 'Rejected');
                setState(() {
                  appointments[index]['status'] =
                      'Rejected';
                });
                Navigator.of(context).pop();
              },
              child: Text('Reject'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _viewAppointmentDetails(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Appointment Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Name: ${appointments[index]['name']}'),
                Text(
                    'Contact Number: ${appointments[index]['contact_number']}'),
                Text(
                    'Appointment Date: ${appointments[index]['appointment_date']}'),
                Text('Status: ${appointments[index]['status']}'),
                Text('Pet Name: ${appointments[index]['pet_name']}'),
                Text('Pet Breed: ${appointments[index]['pet_breed']}'),
                Text('Pet Age: ${appointments[index]['pet_age']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLogOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log Out'),
          content:
              Text('Thank you for using Vetgo. Admin Logged Out successfully!'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin'),
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
      ),
      body: appointments.isEmpty
          ? Center(child: Text('No pending appointments available.'))
          : ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      '${appointments[index]['name']} - ${appointments[index]['appointment_date']}'),
                  subtitle: Text('Status: ${appointments[index]['status']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => _approveAppointment(index),
                        child: Text('Approve'),
                      ),
                      SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () => _viewAppointmentDetails(index),
                        style: ElevatedButton.styleFrom(
                            foregroundColor: Color.fromARGB(255, 255, 228, 109)),
                        child: Text('View'),
                      ),
                      SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () => _rejectAppointment(index),
                        child: Text('Reject'),
                        style: ElevatedButton.styleFrom(
                            foregroundColor: Color.fromARGB(255, 243, 92, 81)),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            label: 'Clinics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Log Out',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update current index based on tapped item
          });

          switch (index) {
            case 0:
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(
              //       builder: (context) => HomePage()), // Navigate to HomePage
              // );
              break;
            case 2:
              // Handle Log Out functionality
              Navigator.pushNamed(context, '/');
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
