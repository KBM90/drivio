import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class SearchDestinationButton extends StatelessWidget {
  final Function(LatLng destination, String destinationName)?
  onDestinationSelected;
  final LatLng? currentLocation;

  const SearchDestinationButton({
    super.key,
    this.onDestinationSelected,
    this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      radius: 24,
      child: IconButton(
        icon: const Icon(Icons.search, color: Colors.black, size: 24),
        onPressed: () {
          _showSearchModal(context);
        },
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SearchDestinationModal(
          onDestinationSelected: onDestinationSelected,
          currentLocation: currentLocation,
        );
      },
    );
  }
}

class SearchDestinationModal extends StatefulWidget {
  final Function(LatLng destination, String destinationName)?
  onDestinationSelected;
  final LatLng? currentLocation;

  const SearchDestinationModal({
    super.key,
    this.onDestinationSelected,
    this.currentLocation,
  });

  @override
  State<SearchDestinationModal> createState() => _SearchDestinationModalState();
}

class _SearchDestinationModalState extends State<SearchDestinationModal> {
  final TextEditingController _searchController = TextEditingController();
  final OSRMService _osrmService = OSRMService();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _osrmService.searchPlaces(
        query,
        lat: widget.currentLocation?.latitude,
        lon: widget.currentLocation?.longitude,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          if (results.isEmpty) {
            _errorMessage = 'No results found';
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error searching places: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Error searching. Please try again.';
          _searchResults = [];
        });
      }
    }
  }

  void _selectDestination(Map<String, dynamic> place) {
    final lat = place['lat'] as double?;
    final lon = place['lon'] as double?;
    final displayName = place['display_name'] as String? ?? 'Unknown Location';

    if (lat != null && lon != null) {
      final destination = LatLng(lat, lon);

      // Call the callback
      widget.onDestinationSelected?.call(destination, displayName);

      // Close the modal
      Navigator.of(context).pop();

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Destination set: $displayName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Search Destination',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search for places, addresses...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _errorMessage = null;
                              });
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _searchPlaces(value);
                    }
                  });
                },
                onSubmitted: _searchPlaces,
              ),
              const SizedBox(height: 16),

              // Current Location Info
              if (widget.currentLocation != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Searching near your location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Nearby Places Categories
              if (widget.currentLocation != null &&
                  _searchResults.isEmpty &&
                  _searchController.text.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nearby Places',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNearbyPlace(Icons.wc, 'Restrooms', 'toilet'),
                        _buildNearbyPlace(
                          Icons.restaurant,
                          'Food',
                          'restaurant',
                        ),
                        _buildNearbyPlace(
                          Icons.local_gas_station,
                          'Gas',
                          'fuel',
                        ),
                        _buildNearbyPlace(
                          Icons.local_hospital,
                          'Hospital',
                          'hospital',
                        ),
                        _buildNearbyPlace(
                          Icons.local_parking,
                          'Parking',
                          'parking',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Results
              Expanded(child: _buildResultsSection(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsSection(ScrollController scrollController) {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search for a destination',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a place name, address, or landmark',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        return _buildPlaceItem(place);
      },
    );
  }

  Widget _buildPlaceItem(Map<String, dynamic> place) {
    final displayName = place['display_name'] as String? ?? 'Unknown';

    // Extract main name and address
    final parts = displayName.split(',');
    final mainName = parts.isNotEmpty ? parts[0].trim() : displayName;
    final address = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: Icon(_getIconForType(place), color: Colors.black87, size: 20),
      ),
      title: Text(
        mainName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
          address.isNotEmpty
              ? Text(
                address,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
              : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _selectDestination(place),
    );
  }

  Widget _buildNearbyPlace(IconData icon, String label, String category) {
    return GestureDetector(
      onTap: () => _searchByCategory(category, label),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[50],
            radius: 28,
            child: Icon(icon, color: Colors.blue[700], size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _searchByCategory(String category, String label) async {
    // Set search text to show what's being searched
    _searchController.text = label;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _osrmService.searchPlaces(
        category,
        lat: widget.currentLocation?.latitude,
        lon: widget.currentLocation?.longitude,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          if (results.isEmpty) {
            _errorMessage = 'No $label found nearby';
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error searching $category: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Error searching. Please try again.';
          _searchResults = [];
        });
      }
    }
  }

  IconData _getIconForType(Map<String, dynamic> place) {
    final type = (place['type'] as String?)?.toLowerCase() ?? '';
    final osmKey = (place['osm_key'] as String?)?.toLowerCase() ?? '';

    // Check osm_key first for more specific categorization
    switch (osmKey) {
      case 'amenity':
        // Check type for amenity subcategories
        if (type.contains('restaurant') ||
            type.contains('cafe') ||
            type.contains('food')) {
          return Icons.restaurant;
        }
        if (type.contains('hospital') ||
            type.contains('clinic') ||
            type.contains('doctor')) {
          return Icons.local_hospital;
        }
        if (type.contains('fuel') || type.contains('gas')) {
          return Icons.local_gas_station;
        }
        if (type.contains('hotel') || type.contains('motel')) {
          return Icons.hotel;
        }
        if (type.contains('school') ||
            type.contains('university') ||
            type.contains('college')) {
          return Icons.school;
        }
        if (type.contains('bank') || type.contains('atm')) {
          return Icons.account_balance;
        }
        if (type.contains('pharmacy')) {
          return Icons.local_pharmacy;
        }
        if (type.contains('parking')) {
          return Icons.local_parking;
        }
        return Icons.place;

      case 'shop':
        if (type.contains('supermarket') || type.contains('mall')) {
          return Icons.shopping_cart;
        }
        return Icons.store;

      case 'tourism':
        if (type.contains('hotel') || type.contains('motel')) {
          return Icons.hotel;
        }
        if (type.contains('museum')) {
          return Icons.museum;
        }
        return Icons.tour;

      case 'leisure':
        if (type.contains('park') || type.contains('garden')) {
          return Icons.park;
        }
        if (type.contains('stadium') || type.contains('sports')) {
          return Icons.sports_soccer;
        }
        return Icons.park;

      case 'highway':
        return Icons.directions;

      case 'building':
        return Icons.business;
    }

    // Fallback to type-based checking
    if (type.contains('city') ||
        type.contains('town') ||
        type.contains('village')) {
      return Icons.location_city;
    }
    if (type.contains('restaurant') ||
        type.contains('cafe') ||
        type.contains('food')) {
      return Icons.restaurant;
    }
    if (type.contains('hotel') || type.contains('motel')) {
      return Icons.hotel;
    }
    if (type.contains('fuel') || type.contains('gas')) {
      return Icons.local_gas_station;
    }
    if (type.contains('hospital') || type.contains('clinic')) {
      return Icons.local_hospital;
    }
    if (type.contains('school') || type.contains('university')) {
      return Icons.school;
    }
    if (type.contains('park') || type.contains('garden')) {
      return Icons.park;
    }
    if (type.contains('airport')) {
      return Icons.flight;
    }
    if (type.contains('train') || type.contains('station')) {
      return Icons.train;
    }
    if (type.contains('bus')) {
      return Icons.directions_bus;
    }
    if (type.contains('street') || type.contains('road')) {
      return Icons.add_road;
    }

    // Default icon
    return Icons.place;
  }
}
