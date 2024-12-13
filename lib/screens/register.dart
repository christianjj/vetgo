import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_file/open_file.dart';
import 'package:vet_go/reusable_widgets/widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'PH');
  String phoneNumberString = '';
  int _age = 0;
  bool _isPasswordVisible = false;
  bool _isCPasswordVisible = false;
  bool _isLoading = false;
  LatLng? _currentLocation;
  final MapController _mapController = MapController();

  // Validation error messages
  String? _fnameError;
  String? _lnameError;
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _addressError;
  String? _phoneError;
  String? _birthdateError;

  Map<String, String?> uploadedFiles = {
    'Passport': null,
    'SSS ID': null,
    'Philhealth ID': null,
    'Drivers License': null,
    'Postal ID': null,
    'National ID': null,
    'TIN ID': null,
  };

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

    Map<String, dynamic> filesToUpload = {};
    uploadedFiles.forEach((key, value) {
      filesToUpload[key] =
          value; // You might need to handle file uploads differently
    });
  }

  // Regular expression for email validation
  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Function to validate fields
  bool _validateFields() {
    bool isValid = true;

    setState(() {
      _fnameError =
          _fnameController.text.isEmpty ? 'First name is required' : null;
      _lnameError =
          _lnameController.text.isEmpty ? 'Last name is required' : null;
      _emailError = _emailController.text.isEmpty
          ? 'Email is required'
          : !_emailRegex.hasMatch(_emailController.text)
              ? 'Enter a valid email'
              : null;
      _passwordError =
          _passwordController.text.isEmpty ? 'Password is required' : null;
      _birthdateError =
          _birthdateController.text.isEmpty ? 'Birthdate is required' : null;
      _addressError =
          _addressController.text.isEmpty ? 'Address is required' : null;
      _phoneError =
          phoneNumberString.isEmpty ? 'Contact number is required' : null;

      // Check if all fields are valid
      isValid = _fnameError == null &&
          _lnameError == null &&
          _emailError == null &&
          _usernameError == null &&
          _passwordError == null &&
          _birthdateError == null &&
          _addressError == null &&
          _phoneError == null;
    });
    return isValid;
  }

  // Function to register user
  registerUser() async {
    setState(() {
      _isLoading = true;
    });
    if (_validateFields()) {

      try {
        // Check if the user email already exists in Authentication
        final List<String> methods = await _auth.fetchSignInMethodsForEmail(
          _emailController.text.trim(),
        );

        if (methods.isNotEmpty) {
          // Email already exists
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This email is already registered.")),
          );
          setState(() {
            _isLoading = false; // Stop loading
          });
          return;
        }

        // Check if the mobile number already exists in Firestore
        // final QuerySnapshot result = await _firestore
        //     .collection('users')
        //     .where('mobileNumber', isEqualTo: phoneNumberString)
        //     .get();

        // if (result.docs.isNotEmpty) {
        //   // Mobile number already exists
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(
        //         content: Text("This mobile number is already registered.")),
        //   );
        //   setState(() {
        //     _isLoading = false; // Stop loading
        //   });
        //   return;
        // }
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'email': _emailController.text.trim(),
          'fname': _fnameController.text.trim(),
          'lname': _lnameController.text.trim(),
          'mobileNumber': phoneNumberString,
          'long': _currentLocation?.longitude,
          'lat': _currentLocation?.latitude,
          'age': _age,
          'address': _addressController.text.trim(),
          'birthdate': _birthdateController.text.trim(),
          'isClinic' : false,
          'createdAt': DateTime.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration Successful")),
        );
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

  // Function to select birthdate using a DatePicker
  Future<void> _selectBirthdate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
        _age = DateTime.now().year - picked.year;
      });
    }
  }

  // Function to get current location using Geolocator
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _addressController.text = '${position.latitude}, ${position.longitude}';
      });

      // Optionally, you can convert coordinates to a human-readable address using the `geocoding` package
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        setState(() {
          _addressController.text =
              '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        });
      }
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register as User"),
        backgroundColor: const Color.fromRGBO(184, 225, 241, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              logoTop('assets/2.png'),
              TextField(
                controller: _fnameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  errorText: _fnameError,
                ),
              ),
              TextField(
                controller: _lnameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  errorText: _lnameError,
                ),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: _emailError,
                ),
              ),
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
              const SizedBox(height: 20),

              // Birthdate Field with Date Picker
              Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: TextField(
                      controller: _birthdateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Birthdate",
                        errorText: _birthdateError,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectBirthdate(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    flex: 1,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Age',
                        hintText: '$_age',
                      ),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Contact Number
              InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  setState(() {
                    phoneNumberString = number.phoneNumber!;
                  });
                },
                onInputValidated: (bool isValid) {
                  print('Phone number is valid: $isValid');
                },
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                ),
                initialValue: _phoneNumber,
                inputDecoration: InputDecoration(
                  labelText: 'Contact Number',
                  errorText: _phoneError,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
                formatInput: true,
                maxLength: 15,
              ),

              const SizedBox(height: 20),

              // Home Address with Flutter Map integration
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Home Address',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.location_on),
                    onPressed: _getCurrentLocation, // Locate current position
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Flutter Map to show current location
              const SizedBox(height: 20),
              SizedBox(height: 20),

              // Document Upload Fields
              Text(
                'Upload Any of the Required Documents',
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
              if (_isLoading)
                Container(
                  color: Colors.transparent, // Semi-transparent background
                  child: const Center(
                    child: CircularProgressIndicator(), // Loading spinner
                  ),
                ),

              ElevatedButton(style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 3,
              ),
                onPressed: () {
                  registerUser();
                },
                child: const SizedBox(
                  width: double.infinity, // Makes the button expand to full width
                  child: Center(
                    child: Text('Register'), // Centers the text
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
