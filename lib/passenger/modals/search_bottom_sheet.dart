import 'dart:async';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:flutter/material.dart';

import 'package:latlong2/latlong.dart';

class SearchBottomSheet extends StatefulWidget {
  const SearchBottomSheet({super.key});

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final OSRMService _osrmService = OSRMService();

  List<Map<String, dynamic>> _suggestions = [];
  String? _countryCode;
  Timer? _debounce;
  bool _isLoading = false;
  bool _isSearchingDestination = false; // Track which field is being searched

  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;

  @override
  void initState() {
    super.initState();
    _fetchUserCountry();
  }

  Future<void> _fetchUserCountry() async {
    final location = await GeolocatorHelper.getCurrentLocation();
    if (location != null) {
      final code = await _osrmService.getCountryCode(
        location.latitude,
        location.longitude,
      );
      setState(() {
        _countryCode = code;
        // Initialize pickup with current location
        _pickupLatLng = LatLng(location.latitude, location.longitude);
      });

      // Optional: Pre-fill pickup with current location name
      final placeName = await _osrmService.getPlaceName(
        location.latitude,
        location.longitude,
      );
      if (mounted) {
        _pickupController.text = placeName;
      }
    }
  }

  void _onSearchChanged(String query, bool isDestination) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _isSearchingDestination = isDestination;
    });

    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isLoading = true);
      final results = await _osrmService.searchPlaces(
        query,
        lat: _pickupLatLng?.latitude,
        lon: _pickupLatLng?.longitude,
        countryCode: _countryCode,
      );
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    });
  }

  void _onSuggestionSelected(Map<String, dynamic> place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final latLng = LatLng(lat, lon);

    if (_isSearchingDestination) {
      _destinationController.text = place['name'];
      _destinationLatLng = latLng;
    } else {
      _pickupController.text = place['name'];
      _pickupLatLng = latLng;
    }

    setState(() {
      _suggestions = [];
    });

    debugPrint('Selected: ${place['display_name']} ($lat, $lon)');
  }

  void _onConfirm() {
    Navigator.pop(context, {
      'pickup': _pickupLatLng,
      'destination': _destinationLatLng,
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9, // Start larger for search
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Plan your trip",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Input Fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _pickupController,
                      onChanged: (val) => _onSearchChanged(val, false),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        hintText: "Enter pick-up",
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _destinationController,
                      onChanged: (val) => _onSearchChanged(val, true),
                      autofocus: true, // Focus destination by default
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.flag),
                        hintText: "Where to?",
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),

              // Suggestions List
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _suggestions.isNotEmpty
                        ? ListView.separated(
                          controller: controller,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final place = _suggestions[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: Colors.grey,
                              ),
                              title: Text(
                                place['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                place['display_name'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () => _onSuggestionSelected(place),
                            );
                          },
                        )
                        : ListView(
                          controller: controller,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.map),
                              title: const Text("Set location on map"),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
              ),

              // Confirm Button
              if (_destinationLatLng != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Confirm",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
