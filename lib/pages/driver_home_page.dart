import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

// A model for a ride request to keep the code clean
class RideRequest {
  final String riderName;
  final String pickupLocation;
  final String dropLocation;
  final String fare;
  final LatLng pickupCoords;

  RideRequest({
    required this.riderName,
    required this.pickupLocation,
    required this.dropLocation,
    required this.fare,
    required this.pickupCoords,
  });
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  // --- IMPORTANT: Add your Google Maps API Key here ---
  static const String _googleMapsApiKey =
      "AIzaSyAadsIdv16FPumbtNJQpnva9GLCl63_di8";

  final Completer<GoogleMapController> _controller = Completer();
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777), // Mumbai (fallback)
    zoom: 12.0,
  );

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final PolylinePoints _polylinePoints = PolylinePoints();

  // --- Dummy data for nearby ride requests ---
  final List<RideRequest> _rideRequests = [
    RideRequest(
      riderName: 'Rohan Sharma',
      pickupLocation: 'Kurla Station',
      dropLocation: 'Phoenix Marketcity',
      fare: '₹120',
      pickupCoords: const LatLng(19.0681, 72.8863),
    ),
    RideRequest(
      riderName: 'Priya Mehta',
      pickupLocation: 'Ghatkopar Metro',
      dropLocation: 'R City Mall',
      fare: '₹95',
      pickupCoords: const LatLng(19.0850, 72.9090),
    ),
    RideRequest(
      riderName: 'Ankit Desai',
      pickupLocation: 'Bandra West',
      dropLocation: 'Juhu Beach',
      fare: '₹150',
      pickupCoords: const LatLng(19.0560, 72.8290),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _handleLocationPermission();
    // REMOVED: We no longer plot all requests on startup. This fixes the bug.
  }

  Future<void> _handleLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      _goToCurrentUserLocation();
    } else {
      var result = await Permission.location.request();
      if (result.isGranted) {
        _goToCurrentUserLocation();
      }
    }
  }

  Future<void> _goToCurrentUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15.0,
        ),
      ));
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
  }

  void _acceptRide(RideRequest request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF4CAF50),
        content: Text('Accepted ride from ${request.riderName}!'),
      ),
    );
  }

  // Test method to verify markers are working
  void _testMarkers() {
    debugPrint("=== Testing markers ===");
    setState(() {
      _markers.clear();
      _polylines.clear();

      // Add a test marker at Mumbai center
      _markers.add(
        Marker(
          markerId: const MarkerId('test_marker'),
          position: const LatLng(19.0760, 72.8777),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Test Marker'),
        ),
      );

      debugPrint("Added test marker. Total markers: ${_markers.length}");
    });
  }

  // --- This function now correctly handles plotting ---
  Future<void> _onRideRequestSelected(RideRequest request) async {
    debugPrint("=== Starting ride request selection ===");
    debugPrint("Selected request: ${request.riderName}");
    debugPrint("Pickup location: ${request.pickupLocation}");
    debugPrint("Pickup coordinates: ${request.pickupCoords}");

    try {
      // Get the driver's current location
      debugPrint("Getting driver's current location...");
      Position driverPosition = await Geolocator.getCurrentPosition();
      LatLng driverCoords =
          LatLng(driverPosition.latitude, driverPosition.longitude);
      debugPrint("Driver coordinates: $driverCoords");

      // Get the route from driver to pickup
      debugPrint("Calculating route from driver to pickup...");
      debugPrint("Using API key: ${_googleMapsApiKey.substring(0, 10)}...");

      PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
        _googleMapsApiKey,
        PointLatLng(driverCoords.latitude, driverCoords.longitude),
        PointLatLng(
            request.pickupCoords.latitude, request.pickupCoords.longitude),
        travelMode: TravelMode.driving,
      );

      debugPrint("Polyline result status: ${result.status}");
      debugPrint("Polyline points count: ${result.points.length}");
      debugPrint("Polyline error message: ${result.errorMessage}");

      List<LatLng> polylineCoordinates = [];

      if (result.points.isEmpty) {
        debugPrint("No polyline points received, using fallback straight line");
        polylineCoordinates = [driverCoords, request.pickupCoords];
      } else {
        polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        debugPrint("Polyline coordinates count: ${polylineCoordinates.length}");
        debugPrint(
            "First few coordinates: ${polylineCoordinates.take(3).toList()}");
      }

      if (mounted) {
        debugPrint("Widget is mounted, updating state...");
        setState(() {
          // 1. CLEAR old markers and polylines
          debugPrint("Clearing old markers and polylines...");
          _markers.clear();
          _polylines.clear();

          // 2. PLOT new driver and pickup markers
          debugPrint("Adding driver marker at: $driverCoords");
          _markers.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: driverCoords,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          );

          debugPrint("Adding pickup marker at: ${request.pickupCoords}");
          _markers.add(
            Marker(
              markerId: MarkerId(request.riderName), // Use a unique ID
              position: request.pickupCoords,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow),
              infoWindow: InfoWindow(
                title: 'Pickup: ${request.riderName}',
                snippet: request.pickupLocation,
              ),
            ),
          );

          // 3. PLOT new route polyline
          debugPrint(
              "Adding polyline with ${polylineCoordinates.length} points");
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route_to_pickup'),
              points: polylineCoordinates,
              color: result.points.isEmpty
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFFFFD700),
              width: result.points.isEmpty ? 3 : 5,
              patterns: result.points.isEmpty
                  ? [PatternItem.dash(20), PatternItem.gap(10)]
                  : [],
            ),
          );

          debugPrint("Final markers count: ${_markers.length}");
          debugPrint("Final polylines count: ${_polylines.length}");
        });
      } else {
        debugPrint("Widget is not mounted, skipping state update");
      }

      // 4. ANIMATE camera to fit the new route
      debugPrint("Animating camera to fit route...");
      await _animateCameraToFitRoute(driverCoords, request.pickupCoords);
      debugPrint("=== Ride request selection completed successfully ===");
    } catch (e) {
      debugPrint("=== ERROR in ride request selection ===");
      debugPrint("Error type: ${e.runtimeType}");
      debugPrint("Error message: $e");
      debugPrint("Stack trace: ${StackTrace.current}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error plotting route: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  Future<void> _animateCameraToFitRoute(LatLng point1, LatLng point2) async {
    try {
      debugPrint("Animating camera to fit route between $point1 and $point2");
      final GoogleMapController controller = await _controller.future;
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(min(point1.latitude, point2.latitude),
            min(point1.longitude, point2.longitude)),
        northeast: LatLng(max(point1.latitude, point2.latitude),
            max(point1.longitude, point2.longitude)),
      );
      debugPrint("Camera bounds: $bounds");
      await controller
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
      debugPrint("Camera animation completed");
    } catch (e) {
      debugPrint("Error animating camera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Karo (Driver)'),
        backgroundColor: const Color(0xFF1C1C1C),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Color(0xFFFFD700)),
            onPressed: _testMarkers,
            tooltip: 'Test Markers',
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFFFFD700)),
            onPressed: () {
              Navigator.of(context).pushNamed('/account');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            flex: 6,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialPosition,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),
          ),
          Flexible(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2E2E2E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, -4))
                ],
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Nearby Ride Requests',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  Expanded(
                    child: _rideRequests.isEmpty
                        ? const Center(
                            child: Text(
                              'No ride requests nearby.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: _rideRequests.length,
                            itemBuilder: (context, index) {
                              final request = _rideRequests[index];
                              return Card(
                                color: Colors.black.withOpacity(0.3),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  onTap: () => _onRideRequestSelected(request),
                                  leading: const Icon(Icons.person_pin_circle,
                                      color: Color(0xFFFFD700), size: 32),
                                  title: Text(
                                    'From: ${request.pickupLocation}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'To: ${request.dropLocation}\nFare: ${request.fare}',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _acceptRide(request),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFD700),
                                      foregroundColor: const Color(0xFF1C1C1C),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Accept'),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
