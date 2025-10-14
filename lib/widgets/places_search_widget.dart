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
  // Session tokens are recommended by Google to group autocomplete requests
  // for billing purposes. A new token should be generated for each session.
  String _sessionToken = const Uuid().v4();

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

  // Use a "debounce" to prevent making an API call on every single keystroke.
  // This waits for the user to stop typing for a moment before searching.
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchPlaces(query);
      } else {
        if (mounted) setState(() => _predictions = []);
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _places.autocomplete(
        query,
        sessionToken: _sessionToken,
        components: [Component(Component.country, 'in')], // Restrict search to India
        language: 'en',
      );

      if (mounted && response.isOkay) {
        setState(() {
          _predictions = response.predictions;
        });
      } else {
        if (mounted) setState(() => _predictions = []);
        debugPrint("Places API Error: ${response.errorMessage}");
      }
    } catch (e) {
      debugPrint("Error searching places: $e");
      if (mounted) setState(() => _predictions = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _places.getDetailsByPlaceId(
        placeId,
        sessionToken: _sessionToken,
        fields: ["formatted_address", "geometry"],
      );

      if (mounted && response.isOkay) {
        final result = response.result;
        final address = result.formattedAddress ?? 'Unknown Address';
        final lat = result.geometry?.location.lat;
        final lng = result.geometry?.location.lng;

        if (lat != null && lng != null) {
          // This is the callback that sends the data back to home_screen.dart
          widget.onPlaceSelected(address, LatLng(lat, lng));
        }
        // A new session begins after a place is selected.
        if (mounted) setState(() => _sessionToken = const Uuid().v4());
      }
    } catch (e) {
      debugPrint("Error getting place details: $e");
    } finally {
      // Don't set isLoading to false here, as the widget will be disposed.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Make the sheet take up most of the screen for a better search experience
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
                // Draggable handle for the bottom sheet
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