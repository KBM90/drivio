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
  final TextEditingController _destinationController = TextEditingController();
  final OSRMService _osrmService = OSRMService();

  List<Map<String, dynamic>> _suggestions = [];
  String? _countryCode;
  String? _currentCity;
  Timer? _debounce;
  bool _isLoading = false;
  bool _locationServicesFailed = false;

  // Pickup is assumed to be current location, but we still track it
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;

  @override
  void initState() {
    super.initState();
    _fetchUserCountry();
  }

  Future<void> _fetchUserCountry() async {
    try {
      final location = await GeolocatorHelper.getCurrentLocation();
      if (location != null && mounted) {
        final code = await _osrmService.getCountryCode(
          location.latitude,
          location.longitude,
        );
        final city = await _osrmService.getCityFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (mounted) {
          setState(() {
            _countryCode = code;
            _currentCity = city;
            _pickupLatLng = LatLng(location.latitude, location.longitude);
            // Show warning if city couldn't be fetched
            _locationServicesFailed = (city == null);
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching user country: $e");
      if (mounted) {
        setState(() {
          _locationServicesFailed = true;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      // Require minimum 3 characters for meaningful search results
      if (query.length < 3) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoading = true);

      // ✅ Don't search without country code to ensure proper filtering
      if (_countryCode == null) {
        debugPrint("⏳ Waiting for country code before searching...");
        setState(() => _isLoading = false);
        return;
      }

      debugPrint(
        "🔍 Searching for '$query' with location: ${_pickupLatLng?.latitude}, ${_pickupLatLng?.longitude}, country: $_countryCode",
      );

      final results = await _osrmService.searchPlaces(
        query,
        lat: _pickupLatLng?.latitude,
        lon: _pickupLatLng?.longitude,
        countryCode: _countryCode,
        radiusKm: 20.0, // Search within 20km radius
      );

      if (mounted) {
        setState(() {
          _suggestions = results ?? [];
          _isLoading = false;
          if (results == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Unable to search. Please check your internet connection.",
                ),
              ),
            );
          }
        });
      }
    });
  }

  void _onSuggestionSelected(Map<String, dynamic> place) {
    final lat = place['lat'] as double;
    final lon = place['lon'] as double;
    final latLng = LatLng(lat, lon);

    _destinationController.text = place['name'];
    _destinationLatLng = latLng;

    setState(() {
      _suggestions = [];
    });

    // Dismiss keyboard
    FocusScope.of(context).unfocus();
  }

  void _onConfirm() {
    Navigator.pop(context, {
      'pickup': _pickupLatLng,
      'destination':
          _destinationLatLng, // Might be null if user wants to set on map
      'action': _destinationLatLng == null ? 'set_on_map' : 'confirm',
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Choose destination",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location services warning
              if (_locationServicesFailed && _currentCity == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Location services unavailable. Search results may be less precise.",
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Inputs Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Destination Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _destinationController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: "Where to go?",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.black,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),

              // Suggestions or Map Option
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _suggestions.isNotEmpty
                        ? ListView.separated(
                          padding: EdgeInsets.zero,
                          controller:
                              controller, // Link to DraggableScrollableSheet
                          itemCount: _suggestions.length,
                          separatorBuilder:
                              (_, __) => const Divider(
                                height: 1,
                                indent: 24,
                                endIndent: 24,
                              ),
                          itemBuilder: (context, index) {
                            final place = _suggestions[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                place['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                place['display_name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => _onSuggestionSelected(place),
                            );
                          },
                        )
                        : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          controller: controller,
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.map,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                "Set location on map",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context, {
                                  'action': 'set_on_map',
                                  'pickup': _pickupLatLng,
                                });
                              },
                            ),
                          ],
                        ),
              ),

              // Confirm Button Area
              if (_destinationLatLng != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Confirm Trip",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
