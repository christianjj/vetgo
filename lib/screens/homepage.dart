import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'clinic_details.dart';
import 'history.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<dynamic> clinicList = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController areaSearchController = TextEditingController();
  int _currentIndex = 0;
  LatLng selectedLocation = LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    fetchClinics();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    selectedLocation = LatLng(position.latitude, position.longitude);
    _sortClinicsByDistance();
    _showMapModal();
  }

  void _showMapModal() {
    final MapController mapController = MapController();
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
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: areaSearchController,
                          decoration: InputDecoration(
                            labelText: 'Search area',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () async {
                          List<Location> locations =
                          await locationFromAddress(areaSearchController.text);

                          if (locations.isNotEmpty) {
                            setModalState(() {
                              selectedLocation = LatLng(locations[0].latitude,
                                  locations[0].longitude);
                              mapController.move(selectedLocation, 13.0);
                            });
                          } else {
                            print("No location found.");
                          }
                        },
                      ),
                    ],
                  ),
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
                    child: const Text('CONFIRM'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _sortClinicsByDistance() {
    setState(() {
      clinicList.sort((a, b) {
        double distanceA = Geolocator.distanceBetween(
          selectedLocation.latitude,
          selectedLocation.longitude,
          double.parse(a['latitude']),
          double.parse(a['longitude']),
        );
        double distanceB = Geolocator.distanceBetween(
          selectedLocation.latitude,
          selectedLocation.longitude,
          double.parse(b['latitude']),
          double.parse(b['longitude']),
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
    });
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    User? user = _auth.currentUser; // fetch user data.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                onConfirm(); // Execute the confirmation action
                Navigator.of(context).pop();
                _auth.signOut(); // for logout user.
                // Close the dialog
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showLogOutDialog() {
    _showConfirmationDialog(
      title: 'Log Out',
      content: 'Do you really wish to logout?',
      onConfirm: () {
        // Handle logout logic here (e.g., navigate to login page or clear session)
        // For now, just show a simple logout message
        Navigator.of(context).pop(); // Close the logout dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            CarouselSlider(
              options: CarouselOptions(height: 100.0, autoPlay: true),
              items: ['assets/2.png', 'assets/banner.gif', 'assets/banner.png']
                  .map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 2,
                      margin: EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(color: Colors.amber),
                      child: Image.asset(i, fit: BoxFit.cover),
                    );
                  },
                );
              }).toList(),
            ),
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
                        icon: Icon(Icons.pin_drop),
                        onPressed: _getCurrentLocation,
                      ),
                      IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          _sortClinicsByDistance();
                        },
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: clinicList.length,
                itemBuilder: (context, index) {
                  final clinic = clinicList[index];
                  return InkWell(
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
                    child: Card(
                      child: ListTile(
                        title: Text(clinic['clinicName'] ?? 'Clinic'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(clinic['clinicAddress'] ?? ''),
                            Text(clinic['ownerName'] ?? ''),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
        currentIndex: _currentIndex,
        items: const <BottomNavigationBarItem>[
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
          // Navigate to HistoryPage when the second item is tapped
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryPage(),
              ),
            );
          }

          // Handle log out logic if necessary
          if (index == 2) {
            _showLogOutDialog();
          }
        },
      ),
    );
  }
}
