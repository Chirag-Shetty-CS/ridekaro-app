import 'dart:async';
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
  final LatLng dropCoords;

  RideRequest({
    required this.riderName,
    required this.pickupLocation,
    required this.dropLocation,
    required this.fare,
    required this.pickupCoords,
    required this.dropCoords,
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
      dropCoords: const LatLng(19.08532, 72.88905), // Phoenix Marketcity
    ),
    RideRequest(
      riderName: 'Priya Mehta',
      pickupLocation: 'Ghatkopar Metro',
      dropLocation: 'R City Mall',
      fare: '₹95',
      pickupCoords: const LatLng(19.0850, 72.9090),
      dropCoords: const LatLng(19.0992, 72.91697), // R City Mall
    ),
    RideRequest(
      riderName: 'Ankit Desai',
      pickupLocation: 'Bandra West',
      dropLocation: 'Juhu Beach',
      fare: '₹150',
      pickupCoords: const LatLng(19.0560, 72.8290),
      dropCoords: const LatLng(19.0400, 72.8200), // Juhu Beach
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
      // Silently handle location errors
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

  // --- This function handles plotting the complete route ---
  Future<void> _onRideRequestSelected(RideRequest request) async {
    try {
      // Get the driver's current location
      Position driverPosition = await Geolocator.getCurrentPosition();
      LatLng driverCoords =
          LatLng(driverPosition.latitude, driverPosition.longitude);

      // Calculate route from driver to pickup
      PolylineResult pickupResult =
          await _polylinePoints.getRouteBetweenCoordinates(
        _googleMapsApiKey,
        PointLatLng(driverCoords.latitude, driverCoords.longitude),
        PointLatLng(
            request.pickupCoords.latitude, request.pickupCoords.longitude),
        travelMode: TravelMode.driving,
      );

      // Calculate route from pickup to drop
      PolylineResult dropResult =
          await _polylinePoints.getRouteBetweenCoordinates(
        _googleMapsApiKey,
        PointLatLng(
            request.pickupCoords.latitude, request.pickupCoords.longitude),
        PointLatLng(request.dropCoords.latitude, request.dropCoords.longitude),
        travelMode: TravelMode.driving,
      );

      if (mounted) {
        setState(() {
          // Clear old markers and polylines
          _markers.clear();
          _polylines.clear();

          // Add driver marker
          _markers.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: driverCoords,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          );

          // Add pickup marker
          _markers.add(
            Marker(
              markerId: MarkerId('pickup_${request.riderName}'),
              position: request.pickupCoords,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow),
              infoWindow: InfoWindow(
                title: 'Pickup: ${request.riderName}',
                snippet: request.pickupLocation,
              ),
            ),
          );

          // Add drop marker
          _markers.add(
            Marker(
              markerId: MarkerId('drop_${request.riderName}'),
              position: request.dropCoords,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: 'Drop: ${request.riderName}',
                snippet: request.dropLocation,
              ),
            ),
          );

          // Plot route from driver to pickup
          if (pickupResult.points.isNotEmpty) {
            List<LatLng> pickupRoute = pickupResult.points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();

            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route_to_pickup'),
                points: pickupRoute,
                color: const Color(0xFF4CAF50), // Green for pickup route
                width: 5,
              ),
            );
          } else {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route_to_pickup'),
                points: [driverCoords, request.pickupCoords],
                color: const Color(0xFF4CAF50),
                width: 3,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
              ),
            );
          }

          // Plot route from pickup to drop
          if (dropResult.points.isNotEmpty) {
            List<LatLng> dropRoute = dropResult.points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();

            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route_to_drop'),
                points: dropRoute,
                color: const Color(0xFFFF6B6B), // Red for drop route
                width: 5,
              ),
            );
          } else {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route_to_drop'),
                points: [request.pickupCoords, request.dropCoords],
                color: const Color(0xFFFF6B6B),
                width: 3,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
              ),
            );
          }
        });
      }

      // Animate camera to fit all points
      await _animateCameraToFitAllPoints(
          driverCoords, request.pickupCoords, request.dropCoords);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error plotting route: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  Future<void> _animateCameraToFitAllPoints(
      LatLng driver, LatLng pickup, LatLng drop) async {
    try {
      final GoogleMapController controller = await _controller.future;

      // Find the bounds that include all three points
      double minLat = [driver.latitude, pickup.latitude, drop.latitude]
          .reduce((a, b) => a < b ? a : b);
      double maxLat = [driver.latitude, pickup.latitude, drop.latitude]
          .reduce((a, b) => a > b ? a : b);
      double minLng = [driver.longitude, pickup.longitude, drop.longitude]
          .reduce((a, b) => a < b ? a : b);
      double maxLng = [driver.longitude, pickup.longitude, drop.longitude]
          .reduce((a, b) => a > b ? a : b);

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      await controller
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 150.0));
    } catch (e) {
      // Silently handle camera animation errors
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
