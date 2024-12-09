import 'dart:convert'; // For JSON encoding/decoding

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:intl/intl.dart'; // For formatting date
import 'package:url_launcher/url_launcher.dart'; // For launching GCash app

class BookAppointmentPage extends StatefulWidget {
  final String clinicId;
  final String clinicName;

  BookAppointmentPage({required this.clinicId, required this.clinicName});

  @override
  _BookAppointmentPageState createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController petNameController = TextEditingController();
  TextEditingController petBreedController = TextEditingController();
  TextEditingController petAgeController = TextEditingController();
  List<Map<String, dynamic>> services = [];
  Map<String, dynamic>? selectedService;
  late String clinicName;
  bool _isLoading = false;
  User? user = FirebaseAuth.instance.currentUser;
  @override
  void initState() {
    super.initState();
    _fetchServices();

  }

  // Function to launch GCash app
  void _openGCashApp() async {
    const url =
        'https://play.google.com/store/apps/details?id=com.globe.gcash.android'; // GCash URL scheme to open the app
    if (await canLaunch(url)) {
      await launch(url); // Opens GCash app if available
    } else {
      // If the GCash app is not installed, show an alert
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('GCash App Not Found'),
            content: Text(
                'Please install the GCash app to proceed with the payment.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

// Function to show appointment confirmation

  void _showSuccessBook() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Appointment has been successfully booked!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/history');
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to fetch services from the backend
  void _fetchServices() async {
    // final response =
    //     await http.get(Uri.parse('http://10.0.2.2/VETGO/fetch_services.php'));
    //
    // if (response.statusCode == 200) {
    //   setState(() {
    //     _services = jsonDecode(response.body);
    //   });
    // } else {
    //   print('Failed to load services');
    // }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('clinic')
          .doc(widget.clinicId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['Services'] != null) {
          setState(() {
            services = List<Map<String, dynamic>>.from(data['Services']);
          });
        }
      }
    } catch (e) {
      print('Error fetching services: $e');
    }
  }

  // Function to show modal with bank details
  void _showBankDetailsModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Clinic Bank Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              // Replace with actual bank details
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(''),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Account Number: 1234-5678-90'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _openGCashApp,
                  child: Text('Pay via GCash'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // Function to validate and submit the form
  void _submitForm() async {
    setState(() {
      _isLoading = true;
    });
    if (_formKey.currentState!.validate()) {
      // Prepare data to send to the backend
      //   final Map<String, dynamic> appointmentData = {
      //     'name': nameController.text,
      //     'contact_number': contactController.text,
      //     'appointment_date': dateController.text,
      //     'pet_name': petNameController.text,
      //     'pet_breed': petBreedController.text,
      //     'pet_age': petAgeController.text,
      //     'service': selectedService,
      //     'clinic_id': widget.clinicId.toString(),
      //   };
      //
      //   // Send data to the PHP script
      //   final response = await http.post(
      //     Uri.parse('http://10.0.2.2/VETGO/insert_appointment.php'),
      //     body: appointmentData,
      //   );
      //
      //   if (response.statusCode == 200) {
      //     final responseData = jsonDecode(response.body);
      //     if (responseData['status'] == 'success') {
      //       // Show bank details after successful submission
      //       _showBankDetailsModal();
      //     } else {
      //       // Show error message
      //       _showErrorDialog(responseData['message']);
      //     }
      //   } else {
      //     // Handle server error
      //     _showErrorDialog('Server error. Please try again later.');
      //   }
      try {
        // Create a user for the shop owner

        // Add shop details to Firestore
        await FirebaseFirestore.instance.collection('appointments').add({
          'name': nameController.text.trim(),
          'contact_number': contactController.text.trim(),
          'appointment_date': dateController.text,
          'pet_name': petNameController.text.trim(),
          'pet_breed': petBreedController.text.trim(),
          'pet_age': petAgeController.text.trim(),
          'service': selectedService,
          'userid': user?.uid,
          'clinic_id': widget.clinicId.toString(),
          'createdAt': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Appointment successfully created")),
        );

        // Navigate to the shop dashboard or login screen
        Navigator.pushNamed(context, '/homepage');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to format date
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Appointment at ${widget.clinicName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name Field
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Your Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              // Contact Number Field
              TextFormField(
                controller: contactController,
                decoration: InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your contact number';
                  }
                  return null;
                },
              ),
              // Date of Appointment Field
              TextFormField(
                controller: dateController,
                decoration: InputDecoration(labelText: 'Date of Appointment'),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(Duration(days: 1)),
                    firstDate: DateTime.now().add(Duration(days: 1)),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      dateController.text = _formatDate(pickedDate);
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date for the appointment';
                  }
                  return null;
                },
              ),
              // Pet Name Field
              TextFormField(
                controller: petNameController,
                decoration: InputDecoration(labelText: 'Pet Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your pet\'s name';
                  }
                  return null;
                },
              ),
              // Pet Breed Field
              TextFormField(
                controller: petBreedController,
                decoration: InputDecoration(labelText: 'Pet Breed'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your pet\'s breed';
                  }
                  return null;
                },
              ),
              // Pet Age Field
              TextFormField(
                controller: petAgeController,
                decoration: InputDecoration(labelText: 'Pet Age'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your pet\'s age';
                  }
                  return null;
                },
              ),
              // Services Dropdown
              DropdownButtonFormField<Map<String, dynamic>>(
                hint: Text('Select a service'),
                value: selectedService,
                onChanged: (newValue) {
                  setState(() {
                    selectedService = newValue;
                  });
                },
                items: services.map((service) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: service,
                    child: Text(
                      '${service['serviceName']} - ₱${service['servicePrice']}',
                    ),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a service';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              // Book Now Button
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Book Now'),
              ),
              SizedBox(
                height: 8,
              ),
              ElevatedButton(
                onPressed: _showSuccessBook,
                child: Text('Paid using GCash'),
                style: ElevatedButton.styleFrom(
                    foregroundColor: Color.fromARGB(255, 255, 228, 109)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
