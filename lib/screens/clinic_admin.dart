import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet_go/screens/ProfilePage.dart';
import 'package:vet_go/screens/logoutDialog.dart';
import 'package:vet_go/screens/vetProfilePage.dart';

class ClinicAdminPage extends StatefulWidget {
  @override
  _ClinicAdminPageState createState() => _ClinicAdminPageState();
}

class _ClinicAdminPageState extends State<ClinicAdminPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> services = [];
  User? currentUser = FirebaseAuth.instance.currentUser;
  String clinicName = "";

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
            clinicName = clinicData['clinicName'] ?? "Default Clinic Name";
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
          List<Map<String, dynamic>> appointments =
              appointmentsSnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Add the document ID to the data
            return data;
          }).toList();

          setState(() {
            this.appointments = appointments; // Save the list to your state
          });
        } else {
          print("No appointments found for this user/clinic.");
        }
      });
    }
    // Query for clinics
  }

  Future<void> addServiceToClinic(
      String clinicId, Map<String, dynamic> newService) async {
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

  Future<void> _editService(
      String serviceId, String newServiceName, String newPrice) async {
    print(newPrice);
    try {
      // Reference to the clinic document
      DocumentReference clinicDocRef =
          FirebaseFirestore.instance.collection('clinic').doc(currentUser!.uid);

      // Fetch the clinic document
      DocumentSnapshot clinicSnapshot = await clinicDocRef.get();

      if (clinicSnapshot.exists) {
        // Get clinic data
        Map<String, dynamic> clinicData =
            clinicSnapshot.data() as Map<String, dynamic>;
        List<dynamic> services = clinicData['Services'];

        print(
            'Current services: $services'); // Debugging: print current services

        // Find the service to edit
        int index =
            services.indexWhere((service) => service['serviceId'] == serviceId);

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
      DocumentReference clinicDocRef =
          FirebaseFirestore.instance.collection('clinic').doc(currentUser!.uid);

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
                    'serviceId': DateTime.now()
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
                _editService(
                    service['serviceId'], updatedServiceName, updatedPrice);
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
  Future<void> _updateAppointmentStatus(int index, String newStatus, String? notes ) async {
    final appointmentId = appointments[index]['id'];
    print(appointments[index]['id']);
    try {
      // Reference the appointment document in Firestore
      DocumentReference appointmentDocRef = FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId);

      // Update the `status` field in Firestore
      await appointmentDocRef.update({
        'status': newStatus,
        'notes' : notes
      });

      setState(() {
        // Update the local appointments list if needed
        int index = appointments
            .indexWhere((appointment) => appointment['id'] == appointmentId);
        if (index != -1) {
          appointments[index]['status'] = newStatus;
          appointments[index]['notes'] = notes;
        }
      });

      print('Appointment status updated successfully');
    } catch (e) {
      print('Failed to update appointment status: $e');
    }
  }

  void _viewAppointmentDetails(int index) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final appointment = appointments[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Appointment Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              _buildAppointmentDetailRow('Name', appointment['name']),
              _buildAppointmentDetailRow(
                  'Contact Number', appointment['contact_number']),
              _buildAppointmentDetailRow(
                  'Appointment Date', appointment['appointment_date']),
              _buildAppointmentDetailRow('Status', appointment['status']),
              _buildAppointmentDetailRow('Pet Name', appointment['pet_name']),
              _buildAppointmentDetailRow('Pet Breed', appointment['pet_breed']),
              _buildAppointmentDetailRow('Pet Age', appointment['pet_age']),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppointmentDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

// Build the appointments list
  Widget _buildAppointmentsList() {
    appointments.sort((a, b) {
      DateTime dateA = (a['createdAt'] as Timestamp).toDate();
      DateTime dateB = (b['createdAt'] as Timestamp).toDate();
      return dateB.compareTo(dateA); // Newest to oldest
    });
    return RefreshIndicator.adaptive(
      onRefresh: _fetchAppointments,
      child: appointments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending appointments available',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later or schedule a new appointment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: appointments.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final appointment = appointments[index];

                return Dismissible(
                  key: Key(appointment['id'].toString()),
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    // Implement delete logic
                  },
                  child: ListTile(
                    title: Text(
                      appointment['name'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,

                          ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['appointment_date'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        _buildStatusChip(context, appointment['status']),
                        const SizedBox(height: 4),
                        Text(
                          appointment['notes'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    trailing:
                        _buildAppointmentActions(context, appointment, index),
                  ),
                );
              },
            ),
    );
  }

// Helper method to create status chips
  Widget _buildStatusChip(BuildContext context, String status) {
    Color textColor;

    switch (status) {
      case 'Pending':
        textColor = Colors.orange;
        break;
      case 'Approve':
        textColor = Colors.green;
        break;
      case 'Completed':
        textColor = Colors.blue;
        break;
      default:
        textColor = Colors.red;
    }

    return Text(
      status,
      style: TextStyle(
        color: textColor,
        fontSize: 14, // Optional: Adjust font size
        fontWeight: FontWeight.w600, // Optional: Adjust weight
      ),
    );
  }
// Helper method to create action buttons based on appointment status

  void _showRejectReasonDialog(BuildContext context, Map<String, dynamic> appointment, int index) {
    final TextEditingController _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the reason for rejecting the appointment:'),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final reason = _reasonController.text.trim();
                if (reason.isNotEmpty) {
                  // Handle the rejection logic
                  _updateAppointmentStatus(index, 'Reject', 'Notes: $reason');
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  // Optionally show an error if the input is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reason cannot be empty')),
                  );
                }
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  void _showApproveDialog(BuildContext context, Map<String, dynamic> appointment, int index) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approve Appointment'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to confirm this appointment?'),
              SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                  _updateAppointmentStatus(index, 'Approve', '');
                  Navigator.of(context).pop(); // Close the dialog
                }
              ,
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentActions(
      BuildContext context, Map<String, dynamic> appointment, int index) {
    switch (appointment['status']) {
      case 'Pending':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonal(
              onPressed: () => _showApproveDialog(context,appointment,index),
              child: const Text('Approve', style: TextStyle(fontSize: 10),),
            ),
            const SizedBox(width: 4),
            FilledButton.tonal(
              onPressed: () => _showRejectReasonDialog(context,appointment, index),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              child: const Text('Reject',style: TextStyle(fontSize: 10)),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _viewAppointmentDetails(index),
            ),
            const SizedBox(width: 4),
          ],
        );
      case 'Approve':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonal(
              onPressed: () => _updateAppointmentStatus(index, 'Completed', ''),
              child: const Text('Complete',style: TextStyle(fontSize: 10)),
            ),
            const SizedBox(width: 4),
            FilledButton.tonal(
              onPressed: () => _updateAppointmentStatus(index, 'No-Show' , ''),
              child: const Text('No-Show',style: TextStyle(fontSize: 10)),
            ),
          ],
        );
      default:
        return IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _viewAppointmentDetails(index),
        );
    }
  }

  Widget _buildServicesList() {
    return services.isEmpty
        ? const Center(
            child: Text(
              'No services available.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
        : ListView.separated(
            itemCount: services.length,
            separatorBuilder: (context, index) => const Divider(
              thickness: 1,
              height: 1,
              color: Colors.grey,
            ),
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(
                      Icons.design_services,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    service['serviceName'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "Price: Php ${service['servicePrice']}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () => _showEditServiceDialog(service),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          String serviceId = service['serviceId'];
                          _showDeleteConfirmationDialog(serviceId);
                        },
                      ),
                    ],
                  ),
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
        title: Text(clinicName),
        backgroundColor: const Color.fromRGBO(184, 225, 241, 1),
        automaticallyImplyLeading: false,
      ),
      body:
          _currentIndex == 0 ? _buildAppointmentsList() : _buildServicesList() ,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.miscellaneous_services_rounded),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => vetProfilePage(),
              ),
            ); // Show logout confirmation dialog
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
