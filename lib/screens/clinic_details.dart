import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
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
  LatLng clinicLocation = LatLng(0, 0);
  double distance = 0.0;
  List<LatLng> routePoints = [];
  String transportationMode = 'driving';

  @override
  void initState() {
    super.initState();
    _getClinicCoordinates();
  }

  Future<void> _getClinicCoordinates() async {
    try {
      List<Location> locations =
          await locationFromAddress(widget.clinic['clinic_address']);
      if (locations.isNotEmpty) {
        setState(() {
          clinicLocation =
              LatLng(locations[0].latitude, locations[0].longitude);
          distance = Geolocator.distanceBetween(
                widget.userLocation.latitude,
                widget.userLocation.longitude,
                clinicLocation.latitude,
                clinicLocation.longitude,
              ) /
              1000;
        });
        // Fetch the route points after clinicLocation is set
        await _getRoute(widget.userLocation, clinicLocation);
      } else {
        print(
            "No locations found for the address: ${widget.clinic['clinic_address']}");
      }
    } catch (e) {
      print("Error fetching clinic coordinates: $e");
    }
  }

  Future<void> _getRoute(LatLng start, LatLng destination) async {
    final url =
        'http://router.project-osrm.org/route/v1/$transportationMode/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full';

    print("Fetching route from URL: $url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Response data: $data");

      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0]['geometry']['coordinates'];
        setState(() {
          routePoints =
              route.map<LatLng>((point) => LatLng(point[1], point[0])).toList();
          print("Route points: $routePoints");
        });
      } else {
        print("No routes found.");
      }
    } else {
      print("Failed to get route: ${response.statusCode}");
    }
  }

  void _setTransportationMode(String mode) {
    setState(() {
      transportationMode = mode;
    });
    _getRoute(widget.userLocation, clinicLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clinic['clinic_name'] ?? ''),
        backgroundColor: Color.fromRGBO(184, 225, 241, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.clinic['clinic_name'] ?? '',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Address: ${widget.clinic['clinic_address'] ?? ''}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Contact: ${widget.clinic['clinic_contact'] ?? ''}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // print("Clinic ID type: ${widget.clinic['id'].runtimeType}");
                // print("Clinic data: ${widget.clinic['id']}");
                int clinicId =
                    int.tryParse(widget.clinic['id'].toString()) ?? 0;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookAppointmentPage(
                      clinicId: clinicId,
                      clinicName: widget.clinic['clinic_name'],
                    ),
                  ),
                );
              },
              child: Text('Book Appointment'),
            ),

            SizedBox(height: 16),
            if (clinicLocation.latitude != 0 &&
                clinicLocation.longitude != 0) ...[
              Text(
                'Distance: ${distance.toStringAsFixed(2)} km',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      (widget.userLocation.latitude + clinicLocation.latitude) /
                          2,
                      (widget.userLocation.longitude +
                              clinicLocation.longitude) /
                          2,
                    ),
                    initialZoom: 13.0,
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
                          point: widget.userLocation,
                          child: Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 40.0,
                          ),
                        ),
                        Marker(
                          point: clinicLocation,
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40.0,
                          ),
                        ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          color: Colors.green,
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              Center(
                  child:
                      CircularProgressIndicator()), // Show loading until location is set
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
