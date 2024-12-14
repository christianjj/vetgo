import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'ProfilePage.dart';
import 'clinic_details.dart';
import 'history.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<dynamic> clinicList = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController areaSearchController = TextEditingController();
  int _currentIndex = 0;
  gmaps.LatLng selectedLocation = gmaps.LatLng(0, 0);
  bool _isLoading = false;
  String query = '';
  List<dynamic> filteredClinics = [];
  late GoogleMapController _googleMapController;

  @override
  void initState() {
    super.initState();

    fetchClinics();
  }

  void _filterClinics(String searchQuery) {
    setState(() {
      query = searchQuery;
      filteredClinics = clinicList.where((clinic) {
        return clinic['clinicName'].toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar('Location permissions are permanently denied.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        selectedLocation = gmaps.LatLng(position.latitude, position.longitude);
      });
      _sortClinicsByDistance();
    } catch (e) {
      _showErrorSnackBar('Error getting location.');
    }
  }

  void _showMapModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      'Select Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: selectedLocation,
                        zoom: 13.0,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _googleMapController = controller;
                      },
                      markers: {
                        Marker(
                          markerId: MarkerId('selected-location'), // Unique ID for the marker
                          position: selectedLocation, // Marker position
                        ),
                      },
                      onTap: (LatLng newPosition) {
                        setModalState(() {
                          selectedLocation = newPosition;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: areaSearchController,
                          decoration: InputDecoration(
                            labelText: 'Search area',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.blue),
                        onPressed: () async {
                          String query = areaSearchController.text.trim();
                          if (query.isEmpty) {
                            _showErrorSnackBar('Search query cannot be empty.');
                            return;
                          }
                          try {
                            List<Location> locations = await locationFromAddress(query);
                            if (locations.isNotEmpty) {
                              LatLng newLocation = LatLng(
                                locations[0].latitude,
                                locations[0].longitude,
                              );
                              setModalState(() {
                                selectedLocation = newLocation;
                                _googleMapController.animateCamera(
                                  CameraUpdate.newLatLngZoom(newLocation, 13.0),
                                );
                              });
                            } else {
                              _showErrorSnackBar('No location found.');
                            }
                          } catch (e) {
                            _showErrorSnackBar('Error searching location.');
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      List<Placemark> placemarks =
                      await placemarkFromCoordinates(
                        selectedLocation.latitude,
                        selectedLocation.longitude,
                      );
                      Placemark place = placemarks[0];
                      String address =
                          "${place.street}, ${place.locality}, ${place.country}";

                      setState(() {
                        searchController.text = address;
                      });

                      Navigator.pop(context);
                    },
                    child: Text('Confirm Location'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _sortClinicsByDistance() {
    setState(() {
      clinicList.sort((a, b) {
        double distanceA = Geolocator.distanceBetween(
          selectedLocation.latitude,
          selectedLocation.longitude,
          double.parse(a['latitude'].toString()),
          double.parse(a['longitude'].toString()),
        );
        double distanceB = Geolocator.distanceBetween(
          selectedLocation.latitude,
          selectedLocation.longitude,
          double.parse(b['latitude'].toString()),
          double.parse(b['longitude'].toString()),
        );
        return distanceA.compareTo(distanceB);
      });
    });
  }

  // Fetch clinics from Firebase Firestore
  Future<void> fetchClinics() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final QuerySnapshot clinicSnapshot =
        await firestore.collection('clinic').get();

    setState(() {
      clinicList = clinicSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add Document ID to the data
        return data;
      }).toList();
      _getCurrentLocation();
    });
  }


  void _handleBottomNavigation(int index) {
    switch (index) {
      case 0:
        // Already on Dashboard, do nothing
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Prevent going back to the login page
          bool isExitingApp = await _showExitConfirmation(context);
          return isExitingApp; // Allow exit if user confirms
        },
    child:  Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Carousel Slider
            CarouselSlider(
              options: CarouselOptions(
                height: 150.0,
                autoPlay: true,
                enlargeCenterPage: true,
              ),
              items: ['assets/2.png', 'assets/banner.gif', 'assets/banner.png']
                  .map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: AssetImage(i),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search nearest veterinary clinic',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.blue),
                        onPressed: () {
                          _filterClinics(searchController.text);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.location_on, color: Colors.red),
                        onPressed: _getCurrentLocation,
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            // Clinics List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: clinicList.length,
                      itemBuilder: (context, index) {
                        final clinic = clinicList[index];
                        return _buildClinicCard(clinic);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    )
    );
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
                _auth.signOut();
                SystemNavigator.pop();
              },
              child: Text('exit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Widget _buildClinicCard(dynamic clinic) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Color.fromRGBO(184, 225, 241, 1),
          child: Icon(Icons.local_hospital, color: Colors.white),
        ),
        title: Text(
          clinic['clinicName'] ?? 'Clinic',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              clinic['clinicAddress'] ?? '',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 4),
            Text(
              'Owner: ${clinic['ownerName'] ?? ''}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Row(
              children: [
            Text(
              '${(Geolocator.distanceBetween(selectedLocation.latitude, selectedLocation.longitude,
                  double.parse(clinic['latitude'].toString()),
                  double.parse(clinic['longitude'].toString())) / 1000).toStringAsFixed(2)} km',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),

            ),
            Icon(
              Icons.location_on,
              color: Colors.red, // Default Google Maps marker color
              size: 24, // Size of the icon
            ),
            ]
            )
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClinicDetailsPage(
                clinic: clinic,
                userLocation: selectedLocation,
              ),
            ),
          );
        },
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
          label: 'Booking',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
      onTap: _handleBottomNavigation,
    );
  }


}
