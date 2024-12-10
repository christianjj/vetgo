import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ClinicAdminPage extends StatefulWidget {
  @override
  _ClinicAdminPageState createState() => _ClinicAdminPageState();
}

class _ClinicAdminPageState extends State<ClinicAdminPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> services = [];
  User? currentUser = FirebaseAuth.instance.currentUser;

  //String clinicId = '1'; // Set the clinic ID
  int _currentIndex = 0; // To track the selected tab (Appointments or Services)

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    getClinicServices(); // Fetch services when the page loads
  }

  // Fetch appointments from the backend

  Future<void> getClinicServices() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Get the document ID of the current user
        String userDocId = currentUser.uid;

        DocumentSnapshot clinicSnapshot = await FirebaseFirestore.instance
            .collection('clinic')
            .doc(userDocId)
            .get();

        if (clinicSnapshot.exists) {
          Map<String, dynamic> clinicData =
          clinicSnapshot.data() as Map<String, dynamic>;
          setState(() {
            services =
            List<Map<String, dynamic>>.from(clinicData['Services'] ?? []);
          });
        } else {
          print("Clinic not found.");
        }
      }
    } catch (e) {
      print("Error fetching services: $e");
    }
  }

  Future<void> _fetchAppointments() async {
    // final response = await http.get(Uri.parse(
    //     'http://10.0.2.2/VETGO/fetch_appointments.php?clinic_id=$clinicId'));
    //
    // if (response.statusCode == 200) {
    //   List<dynamic> fetchedAppointments = json.decode(response.body);
    //   setState(() {
    //     appointments = fetchedAppointments
    //         .where((appointment) => appointment['status'] == 'Pending')
    //         .map((appointment) => Map<String, dynamic>.from(appointment))
    //         .toList();
    //   });
    // } else {
    //   print("Failed to load appointments: ${response.statusCode}");
    // }
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Get the document ID of the current user
      String userDocId = currentUser.uid;

      // Check if the user is a clinic or not
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final QuerySnapshot appointmentsSnapshot = await firestore
          .collection('appointments')
          .where('clinic_id', isEqualTo: userDocId)
          .get();

      setState(() {
        if (appointmentsSnapshot.docs.isNotEmpty) {
          appointments = appointmentsSnapshot.docs
              .map((doc) => Map<String, dynamic>.from(doc.data() as Map))
              .toList();
        } else {
          print("No appointments found for this user/clinic.");
        }
      });
    }
    // Query for clinics
  }

// Fetch services from the backend
//   Future<void> _fetchServices() async {
//     final response =
//     await http.get(Uri.parse('http://10.0.2.2/VETGO/fetch_services.php'));
//
//     if (response.statusCode == 200) {
//       List<dynamic> fetchedServices = json.decode(response.body);
//       setState(() {
//         services = fetchedServices
//             .map((service) => Map<String, dynamic>.from(service))
//             .toList();
//       });
//     } else {
//       print("Failed to load services: ${response.statusCode}");
//     }
//   }

  Future<void> addServiceToClinic(String clinicId,
      Map<String, dynamic> newService) async {
    try {
      DocumentReference clinicRef =
      FirebaseFirestore.instance.collection('clinic').doc(clinicId);

      // Use Firestore's arrayUnion to add a new service
      await clinicRef.update({
        'Services': FieldValue.arrayUnion([newService])
      });
      getClinicServices();
      print("Service added successfully!");
    } catch (e) {
      print("Error adding service: $e");
    }
  }

// Add a service
//   Future<void> _addService(String serviceName) async {
//     final response = await http.post(
//       Uri.parse('http://10.0.2.2/VETGO/add_service.php'),
//       body: {
//         'service_name': serviceName,
//       },
//     );
//     if (response.statusCode == 200) {
//       _fetchServices(); // Reload services after adding
//     } else {
//       print('Failed to add service: ${response.statusCode}');
//     }
//   }

// Edit a service
  Future<void> _editService(String serviceId, String newServiceName, String newPrice) async {
    print(newPrice);
    try {
      // Reference to the clinic document
      DocumentReference clinicDocRef = FirebaseFirestore.instance
          .collection('clinic')
          .doc(currentUser!.uid);

      // Fetch the clinic document
      DocumentSnapshot clinicSnapshot = await clinicDocRef.get();

      if (clinicSnapshot.exists) {
        // Get clinic data
        Map<String, dynamic> clinicData =
        clinicSnapshot.data() as Map<String, dynamic>;
        List<dynamic> services = clinicData['Services'];

        print('Current services: $services'); // Debugging: print current services

        // Find the service to edit
        int index = services.indexWhere((service) => service['serviceId'] == serviceId);

        if (index != -1) {
          // Update the service
          services[index]['serviceName'] = newServiceName;
          services[index]['servicePrice'] = newPrice;

          // Update the document with the modified list
          await clinicDocRef.update({'Services': services});
          print('Service updated successfully');
          getClinicServices();
        } else {
          print('Service not found');
        }
      } else {
        print('Clinic document does not exist');
      }
    } catch (e) {
      print('Error editing service: $e');
    }
  }

// Delete a service
  Future<void> _deleteService(String serviceId) async {
    try {
      // Reference to the clinic document
      DocumentReference clinicDocRef = FirebaseFirestore.instance
          .collection('clinic')
          .doc(currentUser!.uid);

      // Fetch the clinic document
      DocumentSnapshot clinicSnapshot = await clinicDocRef.get();

      if (clinicSnapshot.exists) {
        // Get clinic data
        Map<String, dynamic> clinicData =
        clinicSnapshot.data() as Map<String, dynamic>;
        List<dynamic> services = clinicData['Services'];

        print(
            'Current services: $services'); // Debugging: print current services

        // Filter out the service to delete
        List<dynamic> updatedServices = services
            .where((service) => service['serviceId'] != serviceId)
            .toList();

        print(
            'Updated services: $updatedServices'); // Debugging: print updated services

        // Update the document with the new array
        await clinicDocRef.update({'Services': updatedServices});
        getClinicServices();
        print('Service deleted successfully');
      } else {
        print('Clinic document does not exist');
      }
    } catch (e) {
      print('Error deleting service: $e');
    }
  }

// Show dialog to add a service
  void _showAddServiceDialog() {
    String newServiceName = '';
    String newServicePrice = '';
    User? user = _auth.currentUser;
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
                  newServiceName = value.trim();
                },
                decoration: InputDecoration(hintText: "Enter service name"),
              ),
              SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  newServicePrice = value.trim();
                },
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: "Enter service price"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (newServiceName.isEmpty || newServicePrice.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out all fields')),
                  );
                  return;
                }
                try {
                  // Create the service object
                  Map<String, dynamic> service = {
                    'serviceId': DateTime
                        .now()
                        .millisecondsSinceEpoch
                        .toString(), // Unique ID
                    'serviceName': newServiceName,
                    'servicePrice': newServicePrice,
                  };

                  // Add the service to the clinic
                  await addServiceToClinic(user!.uid, service);

                  // Close the dialog
                  Navigator.of(context).pop();

                  // Optional: Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Service added successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding service: $e')),
                  );
                }
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
    String updatedServiceName = service['serviceName'];
    String updatedPrice = service['servicePrice'];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: updatedServiceName),
                onChanged: (value) {
                  updatedServiceName = value;
                },
                decoration: InputDecoration(hintText: "Enter service name"),
              ),
              TextField(
                controller: TextEditingController(text: updatedPrice),
                onChanged: (value) {
                  updatedPrice = value;
                },
                decoration: InputDecoration(hintText: "Enter price"),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10), // Limit to 10 digits
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Ensure the double parsing and validation
               // double updatedPrice = double.tryParse(updatedPriceName) ?? 0.0;
                _editService(service['serviceId'], updatedServiceName, updatedPrice);
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
          title: Text("${services[index]['serviceName']}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Price: Php ${services[index]['servicePrice']}"),
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
                    String serviceId =
                    services[index]['serviceId'];
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
  void _showDeleteConfirmationDialog(String serviceId) {
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
