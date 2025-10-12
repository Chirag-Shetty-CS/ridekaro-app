import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:uuid/uuid.dart';

class PlacesSearchWidget extends StatefulWidget {
  final String apiKey;
  final Function(String address, LatLng coordinates) onPlaceSelected;

  const PlacesSearchWidget({
    super.key,
    required this.apiKey,
    required this.onPlaceSelected,
  });

  @override
  State<PlacesSearchWidget> createState() => _PlacesSearchWidgetState();
}

class _PlacesSearchWidgetState extends State<PlacesSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  late final GoogleMapsPlaces _places;
  List<Prediction> _predictions = [];
  Timer? _debounce;
  bool _isLoading = false;
  String _sessionToken = const Uuid().v4(); // Generate a unique session token

  @override
  void initState() {
    super.initState();
    _places = GoogleMapsPlaces(apiKey: widget.apiKey);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Use a debounce to prevent excessive API calls
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchPlaces(query);
      } else {
        setState(() => _predictions = []);
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isLoading = true);
    try {
      final response = await _places.autocomplete(
        query,
        sessionToken: _sessionToken,
        components: [Component(Component.country, 'in')], // Restrict to India
        language: 'en',
      );

      if (response.isOkay) {
        setState(() {
          _predictions = response.predictions;
        });
      } else {
        setState(() => _predictions = []);
        debugPrint("Places API Error: ${response.errorMessage}");
      }
    } catch (e) {
      debugPrint("Error searching places: $e");
      setState(() => _predictions = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    setState(() => _isLoading = true);
    try {
      final response = await _places.getDetailsByPlaceId(
        placeId,
        sessionToken: _sessionToken,
        fields: [ "formatted_address", "geometry" ],
      );

      if (response.isOkay) {
        final result = response.result;
        final address = result.formattedAddress ?? 'Unknown Address';
        final lat = result.geometry?.location.lat;
        final lng = result.geometry?.location.lng;

        if (lat != null && lng != null) {
          widget.onPlaceSelected(address, LatLng(lat, lng));
        }
        // Regenerate session token after a successful selection
        setState(() => _sessionToken = const Uuid().v4());
      }
    } catch (e) {
      debugPrint("Error getting place details: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF2E2E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header and Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Handle for the bottom sheet
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Search field
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search for a location...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                    suffixIcon: _isLoading
                        ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                        ),
                      ),
                    )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),

          // Divider
          const Divider(color: Colors.white24, height: 1),

          // Results List
          Expanded(
            child: _predictions.isEmpty
                ? Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'Start typing to find a location'
                    : 'No places found',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Color(0xFFFFD700)),
                  title: Text(
                    prediction.structuredFormatting?.mainText ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    prediction.structuredFormatting?.secondaryText ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    if (prediction.placeId != null) {
                      _getPlaceDetails(prediction.placeId!);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}