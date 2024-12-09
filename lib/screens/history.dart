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

  @override
  void initState() {
    super.initState();
    _fetchAppointmentHistory();
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
                return ListTile(
                  title: Text(
                      '${appointmentHistory[index]['name']} - ${appointmentHistory[index]['appointment_date']}'),
                  subtitle:
                      Text('Status: ${appointmentHistory[index]['status']}'),
                );
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
