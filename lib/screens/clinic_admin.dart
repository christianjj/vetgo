import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClinicAdminPage extends StatefulWidget {
  @override
  _ClinicAdminPageState createState() => _ClinicAdminPageState();
}

class _ClinicAdminPageState extends State<ClinicAdminPage> {
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> services = [];
  String clinicId = '1'; // Set the clinic ID
  int _currentIndex = 0; // To track the selected tab (Appointments or Services)

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _fetchServices(); // Fetch services when the page loads
  }

  // Fetch appointments from the backend
  Future<void> _fetchAppointments() async {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2/VETGO/fetch_appointments.php?clinic_id=$clinicId'));

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

  // Fetch services from the backend
  Future<void> _fetchServices() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2/VETGO/fetch_services.php'));

    if (response.statusCode == 200) {
      List<dynamic> fetchedServices = json.decode(response.body);
      setState(() {
        services = fetchedServices
            .map((service) => Map<String, dynamic>.from(service))
            .toList();
      });
    } else {
      print("Failed to load services: ${response.statusCode}");
    }
  }

  // Add a service
  Future<void> _addService(String serviceName) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/VETGO/add_service.php'),
      body: {
        'service_name': serviceName,
      },
    );
    if (response.statusCode == 200) {
      _fetchServices(); // Reload services after adding
    } else {
      print('Failed to add service: ${response.statusCode}');
    }
  }

  // Edit a service
  Future<void> _editService(int serviceId, String serviceName) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/VETGO/edit_service.php'),
      body: {
        'service_id': serviceId.toString(),
        'service_name': serviceName,
      },
    );
    if (response.statusCode == 200) {
      _fetchServices(); // Reload services after editing
    } else {
      print('Failed to edit service: ${response.statusCode}');
    }
  }

  // Delete a service
  Future<void> _deleteService(int serviceId) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/VETGO/delete_service.php'),
      body: {
        'service_id': serviceId.toString(),
      },
    );
    if (response.statusCode == 200) {
      _fetchServices(); // Reload services after deleting
    } else {
      print('Failed to delete service: ${response.statusCode}');
    }
  }

  // Show dialog to add a service
  void _showAddServiceDialog() {
    String newServiceName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  newServiceName = value;
                },
                decoration: InputDecoration(hintText: "Enter service name"),
              ),
              SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  //newServicePrice = value;
                },
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: "Enter service price"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _addService(newServiceName);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
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

  // Show dialog to edit a service
  void _showEditServiceDialog(Map<String, dynamic> service) {
    String updatedServiceName = service['service_name'];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Service'),
          content: TextField(
            controller: TextEditingController(text: updatedServiceName),
            onChanged: (value) {
              updatedServiceName = value;
            },
            decoration: InputDecoration(hintText: "Enter service name"),
          ),
          actions: <Widget>[
            // Ensure the syntax is correct here
            TextButton(
              onPressed: () {
                int serviceId = int.tryParse(service['id'].toString()) ?? 0;
                _editService(serviceId, updatedServiceName);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
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

  // Show dialog to confirm logout
  void _showLogOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log Out'),
          content: Text('Do you really wish to logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Log Out'),
                      content: Text(
                          'Thank you for using Vetgo. Admin Logged Out successfully!'),
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
                Navigator.pushNamed(context, '/');
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Update appointment status (Approve/Reject)
  Future<void> _updateAppointmentStatus(int index, String newStatus) async {
    final appointmentId = appointments[index]['id']; // Get the appointment ID

    final response = await http.post(
      Uri.parse('http://10.0.2.2/VETGO/update_appointment_status.php'),
      body: {
        'appointment_id': appointmentId.toString(),
        'status': newStatus,
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        appointments[index]['status'] = newStatus; // Update the status locally
      });
      _fetchAppointments(); // Optionally, refetch the updated appointments list
    } else {
      print('Failed to update appointment status: ${response.statusCode}');
    }
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

  // Build the appointments list
  Widget _buildAppointmentsList() {
    return appointments.isEmpty
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
                      onPressed: () =>
                          _updateAppointmentStatus(index, 'Approve'),
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
                      onPressed: () =>
                          _updateAppointmentStatus(index, 'Reject'),
                      child: Text('Reject'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 243, 92, 81)),
                    ),
                  ],
                ),
              );
            },
          );
  }

  // Build the services list
  Widget _buildServicesList() {
    return services.isEmpty
        ? Center(child: Text('No services available.'))
        : ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(services[index]['service_name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showEditServiceDialog(services[index]),
                    ),
                    IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          int serviceId =
                              int.tryParse(services[index]['id'].toString()) ??
                                  0;
                          _showDeleteConfirmationDialog(serviceId);
                        } // Pass the service ID
                        ),
                  ],
                ),
              );
            },
          );
  }

// Show delete confirmation dialog
  void _showDeleteConfirmationDialog(int serviceId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Service'),
          content: Text('Are you sure you want to delete this service?'),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                print(serviceId);
                _deleteService(serviceId); // Call the delete method
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
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
        title: Text('Clinic Admin Dashboard'),
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
        automaticallyImplyLeading: false,
      ),
      body:
          _currentIndex == 0 ? _buildAppointmentsList() : _buildServicesList(),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.miscellaneous_services_rounded),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _showLogOutDialog(); // Show logout confirmation dialog
          } else {
            setState(() {
              _currentIndex = index; // Change the tab
            });
          }
        },
      ),
      floatingActionButton:
          _currentIndex == 1 // Show the FAB only in the services tab
              ? FloatingActionButton(
                  onPressed: _showAddServiceDialog,
                  child: Icon(Icons.add),
                )
              : null, // Hide the FAB in other tabs
    );
  }
}
