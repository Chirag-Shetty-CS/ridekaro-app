import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../widgets/places_search_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _googleMapsApiKey = "AIzaSyAadsIdv16FPumbtNJQpnva9GLCl63_di8";

  // --- Map State ---
  final Completer<GoogleMapController> _controller = Completer();
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777), // Mumbai (fallback)
    zoom: 12.0,
  );
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // --- UI State ---
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  String _selectedVehicle = 'small_car';
  bool _isLoading = false;

  // --- Location Coordinates ---
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;

  // --- Custom Marker Icons ---
  BitmapDescriptor _pickupIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _dropIcon = BitmapDescriptor.defaultMarker;

  final PolylinePoints _polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();
    _setCustomMarkerIcons();
    _handleLocationPermission();
  }

  void _setCustomMarkerIcons() {
    _pickupIcon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _dropIcon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  Future<void> _handleLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      _goToCurrentUserLocation();
    } else if (status.isDenied) {
      var result = await Permission.location.request();
      if (result.isGranted) {
        _goToCurrentUserLocation();
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('Location Permission Required', style: TextStyle(color: Colors.white)),
        content: const Text('This app needs location access to show your position on the map. Please enable it in your device settings.', style: TextStyle(color: Colors.white70)),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Open Settings', style: TextStyle(color: Color(0xFFFFD700))),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _goToCurrentUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
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

  Future<void> _onSubmitRide() async {
    if (_pickupLatLng == null || _dropLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both pickup and drop locations.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final pickupPoint = _pickupLatLng!;
      final dropPoint = _dropLatLng!;

      PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
        _googleMapsApiKey,
        PointLatLng(pickupPoint.latitude, pickupPoint.longitude),
        PointLatLng(dropPoint.latitude, dropPoint.longitude),
        travelMode: TravelMode.driving,
      );

      List<LatLng> polylineCoordinates = [];
      if (result.points.isNotEmpty) {
        polylineCoordinates.addAll(result.points
            .map((point) => LatLng(point.latitude, point.longitude)));
      } else {
        throw Exception(result.errorMessage ?? 'Could not calculate a route.');
      }

      setState(() {
        _markers = {
          Marker(
              markerId: const MarkerId('pickup'),
              position: pickupPoint,
              icon: _pickupIcon,
              infoWindow:
              InfoWindow(title: 'Pickup', snippet: _pickupController.text)),
          Marker(
              markerId: const MarkerId('drop'),
              position: dropPoint,
              icon: _dropIcon,
              infoWindow:
              InfoWindow(title: 'Drop', snippet: _dropController.text)),
        };
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            color: const Color(0xFFFFD700),
            width: 5,
          ),
        };
      });

      _animateCameraToFitRoute(pickupPoint, dropPoint);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _animateCameraToFitRoute(LatLng pickup, LatLng drop) async {
    final GoogleMapController controller = await _controller.future;
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(min(pickup.latitude, drop.latitude), min(pickup.longitude, drop.longitude)),
      northeast: LatLng(max(pickup.latitude, drop.latitude), max(pickup.longitude, drop.longitude)),
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Karo'),
        backgroundColor: const Color(0xFF1C1C1C),
        automaticallyImplyLeading: false,
        // --- THIS IS THE NEW CODE ---
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFFFFD700)),
            onPressed: () {
              // Navigate to the account page
              Navigator.of(context).pushNamed('/account');
            },
          ),
        ],
        // --- END OF NEW CODE ---
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
              padding: const EdgeInsets.only(bottom: 40, right: 10),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLocationTextField(
                        controller: _pickupController,
                        hint: 'Search Pickup Location',
                        icon: Icons.my_location,
                        isPickup: true),
                    const SizedBox(height: 16),
                    _buildLocationTextField(
                        controller: _dropController,
                        hint: 'Search Drop Location',
                        icon: Icons.location_on,
                        isPickup: false),
                    const SizedBox(height: 24),
                    _buildVehicleSelector(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isPickup,
  }) {
    return GestureDetector(
      onTap: () => _showPlacesSearch(isPickup),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  void _showPlacesSearch(bool isPickup) {
    final navigator = Navigator.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlacesSearchWidget(
        apiKey: _googleMapsApiKey,
        onPlaceSelected: (String address, LatLng coordinates) {
          if (mounted) {
            setState(() {
              if (isPickup) {
                _pickupController.text = address;
                _pickupLatLng = coordinates;
              } else {
                _dropController.text = address;
                _dropLatLng = coordinates;
              }
            });
          }
          navigator.pop();
        },
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildVehicleButton('small_car', Icons.directions_car, 'Small'),
        _buildVehicleButton('big_car', Icons.directions_car_filled, 'Large'),
        _buildVehicleButton('auto', Icons.electric_rickshaw, 'Auto'),
        _buildVehicleButton('bike', Icons.two_wheeler, 'Bike'),
      ],
    );
  }

  Widget _buildVehicleButton(String vehicleType, IconData icon, String label) {
    final bool isSelected = _selectedVehicle == vehicleType;
    return GestureDetector(
      onTap: () {
        if(mounted) setState(() => _selectedVehicle = vehicleType);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFD700)
                  : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey.shade700,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFFFD700)
                      : Colors.grey.shade400,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFCC00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onSubmitRide,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1C1C1C)),
        )
            : const Text(
          'Request Ride',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1C),
          ),
        ),
      ),
    );
  }
}

