import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_file/open_file.dart';

class ClinicRegistrationPage extends StatefulWidget {
  @override
  _ClinicRegistrationPageState createState() => _ClinicRegistrationPageState();
}

class _ClinicRegistrationPageState extends State<ClinicRegistrationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController ownerEmailController = TextEditingController();
  final TextEditingController ownerIdController = TextEditingController();
  final TextEditingController clinicNameController = TextEditingController();
  final TextEditingController clinicAddressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String registrationNumber = '';
  LatLng selectedLocation = LatLng(0, 0);
  String? _passwordError;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Store file paths for the documents
  Map<String, String?> uploadedFiles = {
    'Veterinarian License': null,
    'PRC Registration': null,
    'PTR': null,
    'Dangerous Drugs License or S2': null,
    'Veterinary Diploma': null,
    'BIR': null,
  };

  @override
  void dispose() {
    ownerNameController.dispose();
    ownerEmailController.dispose();
    ownerIdController.dispose();
    clinicNameController.dispose();
    clinicAddressController.dispose();
    super.dispose();
  }

  // File picker function
  Future<void> _pickFile(String documentType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx', 'pdf', 'img', 'jpg', 'png', 'gif'],
    );

    if (result != null && result.files.single.path != null) {
      String? filePath = result.files.single.path;
      setState(() {
        uploadedFiles[documentType] = filePath; // Store file path
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _showMapModal();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location')),
      );
    }
  }

  void _viewDocument(String? filePath) async {
    if (filePath != null) {
      // Attempt to open the file using OpenFile
      final result = await OpenFile.open(filePath);
      if (result.type == ResultType.error) {
        // Show an error if the file can't be opened
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Could not open the document.'),
              actions: [
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _showMapModal() {
    final MapController mapController = MapController();
    final TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              labelText: 'Search location',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (query) async {
                              if (query.isNotEmpty) {
                                try {
                                  // Geocode the search query
                                  List<Location> locations =
                                      await locationFromAddress(query);
                                  if (locations.isNotEmpty) {
                                    // Update map position based on the search result
                                    Location location = locations.first;
                                    setModalState(() {
                                      selectedLocation = LatLng(
                                          location.latitude,
                                          location.longitude);
                                      mapController.move(
                                          selectedLocation, 13.0);
                                    });
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Location not found')),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () async {
                            String query = searchController.text;
                            if (query.isNotEmpty) {
                              try {
                                // Geocode the search query
                                List<Location> locations =
                                    await locationFromAddress(query);
                                if (locations.isNotEmpty) {
                                  // Update map position based on the search result
                                  Location location = locations.first;
                                  setModalState(() {
                                    selectedLocation = LatLng(
                                        location.latitude, location.longitude);
                                    mapController.move(selectedLocation, 13.0);
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Location not found')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: selectedLocation,
                            initialZoom: 13.0,
                            onTap: (tapPosition, LatLng newPosition) {
                              setModalState(() {
                                selectedLocation = newPosition;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                              subdomains: ['a', 'b', 'c'],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: selectedLocation,
                                  width: 80.0,
                                  height: 80.0,
                                  child: Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: const EdgeInsets.all(10),
                                child: FloatingActionButton(
                                  heroTag: null,
                                  onPressed: () {
                                    setModalState(() {
                                      mapController.move(
                                        mapController.camera.center,
                                        mapController.camera.zoom + 1,
                                      );
                                    });
                                  },
                                  child: const Icon(Icons.zoom_in),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(10),
                                child: FloatingActionButton(
                                  heroTag: null,
                                  onPressed: () {
                                    setModalState(() {
                                      mapController.move(
                                        mapController.camera.center,
                                        mapController.camera.zoom - 1,
                                      );
                                    });
                                  },
                                  child: const Icon(Icons.zoom_out),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        List<Placemark> placemarks =
                            await placemarkFromCoordinates(
                          selectedLocation.latitude,
                          selectedLocation.longitude,
                        );
                        if (placemarks.isNotEmpty) {
                          Placemark place = placemarks[0];
                          String address =
                              "${place.street}, ${place.locality}, ${place.country}";

                          setState(() {
                            clinicAddressController.text =
                                address; // Set address to text field
                          });
                        }
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to get address')),
                        );
                      }
                    },
                    child: Text('CONFIRM LOCATION'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  _submitForm() async {
    setState(() {
      _isLoading = true;
    });
    Map<String, dynamic> filesToUpload = {};
    uploadedFiles.forEach((key, value) {
      filesToUpload[key] =
          value; // You might need to handle file uploads differently
    });
    bool allFilesUploaded =
        uploadedFiles.values.every((filePath) => filePath != null);
    if (_formKey.currentState!.validate()) {
      // Check if all required files are uploaded
      if (!allFilesUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload all required documents')),
        );
        return;
      } else {
        setState(() {
          _isLoading = false;
        });
      }

      try {
        // Create a user for the shop owner
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: ownerEmailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Add shop details to Firestore
        await _firestore
            .collection('clinic')
            .doc(userCredential.user?.uid)
            .set({
          'ownerName': ownerNameController.text.trim(),
          'ownerId': ownerIdController.text.trim(),
          'clinicName': clinicNameController.text.trim(),
          'clinicAddress': clinicAddressController.text.trim(),
          'latitude': selectedLocation.latitude,
          'longitude': selectedLocation.longitude,
          'registration_number': registrationNumber,
          'isClinic': true,
          'userType': "clinic",
          'uploaded_files': filesToUpload,
          'createdAt': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Clinic Registered Successfully")),
        );

        // Navigate to the shop dashboard or login screen
        Navigator.pushNamed(context, '/clinic_admin');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }

      // Submit the form data to the server
      // String ownerName = ownerNameController.text;
      // String ownerEmail = ownerEmailController.text;
      // String ownerId = ownerIdController.text;
      // String clinicName = clinicNameController.text;
      // String clinicAddress = clinicAddressController.text;
      //
      // // Prepare files for upload (if your API expects file paths or base64)
      // // Here, we'll assume you send file paths as strings. Adjust accordingly.
      // Map<String, dynamic> filesToUpload = {};
      // uploadedFiles.forEach((key, value) {
      //   filesToUpload[key] =
      //       value; // You might need to handle file uploads differently
      // });
      //
      // // Send API request to register clinic
      // final response = await http.post(
      //   Uri.parse(
      //       'http://10.0.2.2/VETGO/register_clinic.php'), // Update with your API endpoint
      //   headers: <String, String>{
      //     'Content-Type': 'application/json; charset=UTF-8',
      //   },
      //   body: jsonEncode(<String, dynamic>{
      //     'owner_name': ownerName,
      //     'owner_email': ownerEmail,
      //     'owner_id_number': ownerId,
      //     'clinic_name': clinicName,
      //     'clinic_address': clinicAddress,
      //     'latitude': selectedLocation.latitude,
      //     'longitude': selectedLocation.longitude,
      //     'registration_number': registrationNumber,
      //     'uploaded_files': filesToUpload, // Include uploaded file paths
      //   }),
      // );
      //
      // if (response.statusCode == 200) {
      //   final responseBody = jsonDecode(response.body);
      //   if (responseBody['error'] != null) {
      //     // Handle specific error messages
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text(responseBody['error'])),
      //     );
      //   } else {
      //     // Successfully registered
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Clinic registered successfully!')),
      //     );
      //     // Navigate to the admin home page
      //     Navigator.pushReplacementNamed(
      //         context, '/clinic_admin'); // Ensure you have this route set up
      //   }
      // } else {
      //   // Error registering
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Failed to register clinic!')),
      //   );
      // }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clinic Registration'),
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // Changed from Column to ListView for better scrolling
            children: [
              TextFormField(
                controller: ownerNameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the owner name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: ownerEmailController,
                decoration: InputDecoration(labelText: 'Email Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the email address';
                  }
                  // Simple email validation
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: ownerIdController,
                decoration: InputDecoration(labelText: 'ID Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the ID number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: clinicNameController,
                decoration: InputDecoration(labelText: 'Clinic Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the clinic name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: clinicAddressController,
                decoration: InputDecoration(
                  labelText: 'Clinic Address',
                  suffixIcon: IconButton(
                    onPressed: _getCurrentLocation,
                    icon: Icon(Icons.pin_drop),
                  ),
                ),
                readOnly: true, // Make it read-only since it's set via map
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the clinic address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Registration Number'),
                onChanged: (value) {
                  registrationNumber = value; // Store registration number
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the registration number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Document Upload Fields
              Text(
                'Upload Required Documents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Divider(),
              ...uploadedFiles.keys.map((documentType) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(documentType),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                uploadedFiles[documentType] != null
                                    ? Icons.check_circle
                                    : Icons.upload_file,
                                color: uploadedFiles[documentType] != null
                                    ? Colors.green
                                    : null,
                              ),
                              onPressed: () => _pickFile(documentType),
                            ),
                            // IconButton(
                            //     icon: Icon(Icons.remove_red_eye),
                            //     onPressed: () {
                            //       _viewDocument(uploadedFiles[documentType]);
                            //       print(uploadedFiles[documentType]);
                            //     }),
                          ],
                        ),
                      ],
                    ),
                  )),
              SizedBox(height: 20),
              if (_isLoading)
                Stack(children: [
                  Container(
                    color: Colors.white,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                ]),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                ),
                onPressed: _submitForm,
                child: const SizedBox(
                  width: double.infinity,
                  // Makes the button expand to full width
                  child: Center(
                    child: Text('Register Clinic'), // Centers the text
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
