import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'book_appointment.dart';

class ClinicDetailsPage extends StatefulWidget {
  final Map<String, dynamic> clinic;
  final LatLng userLocation;

  ClinicDetailsPage({required this.clinic, required this.userLocation});

  @override
  _ClinicDetailsPageState createState() => _ClinicDetailsPageState();
}

class _ClinicDetailsPageState extends State<ClinicDetailsPage> {
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  String _googleApiKey = "AIzaSyAkCpNMB4Q_JuZzsQ51qiBXcQeiNRScmSQ";

  LatLng clinicLocation = LatLng(0, 0);
  double distance = 0.0;
  List<LatLng> routePoints = [];
  String transportationMode = 'driving';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeClinicData();
  }

  Future<void> _initializeClinicData() async {
    print('clinic location ${widget.clinic}');
    try {
      await _getClinicCoordinates();
      if (clinicLocation.latitude != 0 && clinicLocation.longitude != 0) {
        await _getRoute(widget.userLocation, clinicLocation);
      }
    } catch (e) {
      print("Error during initialization: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getClinicCoordinates() async {
    try {
      // Simulated geocoding result for the clinic address
      clinicLocation = LatLng(widget.clinic['latitude'], widget.clinic['longitude']); // Replace with real geocoding
      distance = Geolocator.distanceBetween(
        widget.userLocation.latitude,
        widget.userLocation.longitude,
        clinicLocation.latitude,
        clinicLocation.longitude,
      ) /
          1000;
    } catch (e) {
      print("Error fetching clinic coordinates: $e");
    }
  }

  Future<void> _getRoute(LatLng start, LatLng destination) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$transportationMode&key=$_googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if ((data['routes'] as List).isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final polylineCoordinates = _decodePolyline(points);

          setState(() {
            routePoints = polylineCoordinates;
          });

          // Adjust the camera to show the entire route
          LatLngBounds bounds = LatLngBounds(
            southwest: LatLng(
              min(widget.userLocation.latitude, clinicLocation.latitude),
              min(widget.userLocation.longitude, clinicLocation.longitude),
            ),
            northeast: LatLng(
              max(widget.userLocation.latitude, clinicLocation.latitude),
              max(widget.userLocation.longitude, clinicLocation.longitude),
            ),
          );

          _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));

        } else {
          print("No routes found");
        }
      } else {
        print("Failed to fetch directions: ${response.body}");
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }


  double _calculateDistance(lat1, lon1, lat2, lon2) {
        const double radiusOfEarthKm = 6371;
        double dLat = _degreeToRadian(lat2 - lat1);
        double dLon = _degreeToRadian(lon2 - lon1);

        double a = (sin(dLat / 2) * sin(dLat / 2)) +
            cos(_degreeToRadian(lat1)) *
                cos(_degreeToRadian(lat2)) *
                sin(dLon / 2) *
                sin(dLon / 2);

        double c = 2 * atan2(sqrt(a), sqrt(1 - a));
        return radiusOfEarthKm * c;
      }

      double _degreeToRadian(degree) {
        return degree * pi / 180;
      }

      List<LatLng> _decodePolyline(String encoded) {
        List<LatLng> polylineCoordinates = [];
        int index = 0,
            len = encoded.length;
        int lat = 0,
            lng = 0;

        while (index < len) {
          int shift = 0,
              result = 0;
          int b;
          do {
            b = encoded.codeUnitAt(index++) - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
          } while (b >= 0x20);
          int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
          lat += dlat;

          shift = 0;
          result = 0;
          do {
            b = encoded.codeUnitAt(index++) - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
          } while (b >= 0x20);
          int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
          lng += dlng;

          polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
        }

        return polylineCoordinates;
      }


    void _setTransportationMode(String mode) {
      setState(() {
        transportationMode = mode;
        isLoading = true;
      });
      print('${widget.userLocation} + ${clinicLocation}');
      _getRoute(widget.userLocation, clinicLocation).then((_) {
        setState(() {
          isLoading = false;
        });
      });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clinic['clinicName'] ?? ''),
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.clinic['clinicAddress'] ?? '',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Distance: ${distance.toStringAsFixed(2)} km',
              style: TextStyle(fontSize: 18),
            ),
            ElevatedButton(
              onPressed: () {
                // print("Clinic ID type: ${widget.clinic['id'].runtimeType}");
                // print("Clinic data: ${widget.clinic['id']}");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookAppointmentPage(
                      clinicId: widget.clinic['id'],
                      clinicName: widget.clinic['clinicName'],
                    ),
                  ),
                );
              },
              child: Text('Book Appointment'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (widget.userLocation.latitude + clinicLocation.latitude) / 2,
                    (widget.userLocation.longitude + clinicLocation.longitude) / 2,
                  ),
                  zoom: 13.0,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId('user'),
                    position: widget.userLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    infoWindow: InfoWindow(title: 'Your Location'),
                  ),
                  Marker(
                    markerId: MarkerId('clinic'),
                    position: clinicLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    infoWindow: InfoWindow(title: 'Clinic Location'),
                  ),
                },
                polylines: {
                  if (routePoints.isNotEmpty)
                    Polyline(
                      polylineId: PolylineId('route'),
                      points: routePoints,
                      color: Colors.red,
                      width: 4,
                    ),
                },
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.motorcycle),
            label: 'Motorbike',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Car',
          ),
        ],
        currentIndex: transportationMode == 'driving' ? 1 : 0,
        onTap: (index) {
          _setTransportationMode(index == 0 ? 'motorcycle' : 'driving');
        },
      ),
    );
  }
}