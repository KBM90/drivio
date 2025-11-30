import 'dart:async';

import 'package:drivio_app/common/constants/routes.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  Timer? _debounce;
  List<String> _citySuggestions = [];
  OSRMService _osrmService = OSRMService();

  String _selectedRole = 'passenger'; // Default role
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedCity;
  String? _userCountryCode;
  String? _userPhone;
  String? _selectedPhoneCountryCode;
  String? _selectedProviderType;
  LatLng? _currentUserLocation;

  final List<Map<String, String>> _providerTypes = [
    {'value': 'mechanic', 'label': 'Mechanic'},
    {'value': 'cleaner', 'label': 'Cleaner'},
    {'value': 'electrician', 'label': 'Electrician'},
    {'value': 'insurance', 'label': 'Insurance'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _getUserCountryCode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
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

  void _onCitySelected(String city) {
    setState(() {
      _selectedCity = city;
      _cityController.text = city;
    });
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

  Widget _buildPhoneFilter() {
    return IntlPhoneField(
      key: ValueKey(_userCountryCode ?? 'US'),
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.green[50],
      ),
      keyboardType: TextInputType.phone,
      initialCountryCode: _userCountryCode ?? 'US',
      onChanged: (phone) {
        setState(() {
          _userPhone = phone.completeNumber;
          _selectedPhoneCountryCode = phone.countryCode;
        });
      },
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required fields that aren't in the form
    if (_userCountryCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to detect country. Please check location permissions.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_userPhone == null || _userPhone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a city.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final normalizedCity = OSRMService().normalizeCity(_selectedCity!);

      // Prepare additional data for provider role
      Map<String, dynamic>? additionalData;
      if (_selectedRole == 'provider') {
        additionalData = {
          'business_name': _businessNameController.text.trim(),
          'provider_type': _selectedProviderType,
        };
      }

      final response = await AuthService.signUpWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        city: normalizedCity,
        countryCode: _userCountryCode!,
        phone: _userPhone!,
        password: _passwordController.text.trim(),
        role: _selectedRole,
        additionalData: additionalData,
      );

      if (response.user != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! Please check your email to verify.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to login screen
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // App Logo or Title
                const Icon(Icons.drive_eta, size: 80, color: Colors.blue),
                const SizedBox(height: 10),
                const Text(
                  'Drivio',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green[300]!),
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.green,
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
                  ),
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    // Check if name contains only letters, spaces, hyphens, and apostrophes
                    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
                      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildCityFilter(),
                const SizedBox(height: 16),
                _buildPhoneFilter(),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green[300]!),
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.green,
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
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green[300]!),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.green,
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
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        );
                      },
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.green,
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green[600]!,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Provider-specific fields (shown only when provider role is selected)
                if (_selectedRole == 'provider') ...[
                  // Business Name Field
                  TextFormField(
                    controller: _businessNameController,
                    decoration: InputDecoration(
                      labelText: 'Business Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[300]!),
                      ),
                      prefixIcon: const Icon(
                        Icons.business,
                        color: Colors.green,
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
                    ),
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (_selectedRole == 'provider') {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your business name';
                        }
                        if (value.trim().length < 2) {
                          return 'Business name must be at least 2 characters';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Provider Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedProviderType,
                    decoration: InputDecoration(
                      labelText: 'Provider Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[300]!),
                      ),
                      prefixIcon: const Icon(
                        Icons.category,
                        color: Colors.green,
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
                    ),
                    items:
                        _providerTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type['value'],
                            child: Text(type['label']!),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProviderType = value;
                      });
                    },
                    validator: (value) {
                      if (_selectedRole == 'provider' && value == null) {
                        return 'Please select a provider type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Role Selection
                const Text(
                  'I want to sign up as:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Role Cards
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        title: 'Passenger',
                        icon: Icons.person,
                        isSelected: _selectedRole == 'passenger',
                        onTap: () {
                          setState(() => _selectedRole = 'passenger');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        title: 'Driver',
                        icon: Icons.drive_eta,
                        isSelected: _selectedRole == 'driver',
                        onTap: () {
                          setState(() => _selectedRole = 'driver');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        title: 'Provider',
                        icon: Icons.store,
                        isSelected: _selectedRole == 'provider',
                        onTap: () {
                          setState(() => _selectedRole = 'provider');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Sign Up Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushReplacementNamed(AppRoutes.login);
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Role Selection Card Widget
class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
