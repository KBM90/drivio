import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/provided_service.dart';
import '../../provider/services/provided_services_service.dart';
import '../helpers/osrm_services.dart';
import '../helpers/geolocator_helper.dart';
import 'package:latlong2/latlong.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final ProvidedServicesService _servicesService = ProvidedServicesService();
  final OSRMService _osrmService = OSRMService();
  final TextEditingController _cityController = TextEditingController();

  List<ProvidedService> _services = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String? _selectedCity;
  String? _userCountryCode;
  LatLng? _currentUserLocation;
  List<String> _citySuggestions = [];
  Timer? _debounce;

  final List<String> _categories = [
    'All',
    'Mechanic',
    'Cleaner',
    'Electrician',
    'Insurance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
    _getUserCountryCode();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getUserCountryCode() async {
    try {
      final location = await GeolocatorHelper.getCurrentLocation();

      if (location != null) {
        final countryCode = await _osrmService.getCountryCode(
          location.latitude,
          location.longitude,
        );

        if (mounted) {
          setState(() {
            _userCountryCode = countryCode;
            _currentUserLocation = location;
          });
        }
      } else {
        debugPrint('⚠️ Location is null - user may have denied permission');
      }
    } catch (e) {
      debugPrint('❌ Error getting country code: $e');
    }
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    final category = _selectedCategory == 'All' ? null : _selectedCategory;

    // Normalize the city before passing it to getServices
    String? city = _selectedCity?.trim();
    if (city != null && city.isNotEmpty) {
      city = OSRMService().normalizeCity(city);
    }

    final services = await _servicesService.getServices(
      category: category,
      city: city,
    );

    if (mounted) {
      setState(() {
        _services = services;
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadServices();
  }

  void _onCitySelected(String city) {
    setState(() {
      _selectedCity = city;
      _cityController.text = city;
    });
    _loadServices();
  }

  Future<void> _searchCities(String query) async {
    if (query.trim().length < 2) {
      setState(() => _citySuggestions = []);
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      // Retry fetching country code if null
      if (_userCountryCode == null) {
        debugPrint('⚠️ Country code is null, retrying fetch...');
        await _getUserCountryCode();
      }

      try {
        final suggestions = await _osrmService.searchCities(
          query,
          countryCode: _userCountryCode,
          lat: _currentUserLocation?.latitude,
          lon: _currentUserLocation?.longitude,
        );

        if (mounted) {
          setState(() {
            _citySuggestions = suggestions;
          });
        } else {
          debugPrint('⚠️ Widget not mounted, skipping state update');
        }
      } catch (e) {
        debugPrint('❌ Error searching cities: $e');
      }
    });
  }

  void _clearCityFilter() {
    setState(() {
      _selectedCity = null;
      _cityController.clear();
      _citySuggestions = [];
    });
    _loadServices();
  }

  Widget _buildCityFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: 'Search city...',
                    prefixIcon: const Icon(
                      Icons.location_city,
                      color: Colors.green,
                    ),

                    suffixIcon:
                        _selectedCity != null
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearCityFilter,
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green[600]!,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.green[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _searchCities,
                ),
              ),
            ],
          ),
          if (_citySuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _citySuggestions.length,
                itemBuilder: (context, index) {
                  final city = _citySuggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, size: 20),
                    title: Text(city),
                    onTap: () {
                      _onCitySelected(city);
                      setState(() => _citySuggestions = []);
                    },
                    dense: true,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCityFilter(),
          _buildCategoryFilter(),

          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _services.isEmpty
                    ? const Center(child: Text('No services found'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        return _buildServiceCard(_services[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected =
              _selectedCategory == category ||
              (_selectedCategory == null && category == 'All');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _onCategorySelected(category);
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue[100],
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue[900] : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: Colors.blue[900],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(ProvidedService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (service.imageUrls!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: _buildServiceImage(service.imageUrls!.first),
            )
          else
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${service.price} ${service.currency}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (service.description != null)
                  Text(
                    service.description!,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          service.providerPhone ?? 'No phone',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (service.providerPhone != null)
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final Uri launchUri = Uri(
                              scheme: 'tel',
                              path: service.providerPhone,
                            );
                            if (await canLaunchUrl(launchUri)) {
                              await launchUrl(launchUri);
                            }
                          },
                          icon: const Icon(Icons.call, size: 14),
                          label: const Text(
                            'Call',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceImage(String imageUrl) {
    if (imageUrl.startsWith('default:')) {
      final type = imageUrl.split(':')[1];
      return Image.asset(
        'assets/service/$type.png',
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Container(
              height: 150,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
      );
    }

    return Image.network(
      imageUrl,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder:
          (context, error, stackTrace) => Container(
            height: 150,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
          ),
    );
  }
}
