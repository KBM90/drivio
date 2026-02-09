import 'dart:async';
import 'package:provider/provider.dart';
import 'package:drivio_app/common/providers/locale_provider.dart';

import 'package:drivio_app/common/constants/routes.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drivio_app/common/constants/app_theme.dart';
import 'package:drivio_app/common/l10n/app_localizations.dart';

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
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final OSRMService _osrmService = OSRMService();

  String _selectedRole = 'passenger'; // Default role
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _userCountryCode;
  String? _userPhone;
  String? _selectedPhoneCountryCode;
  String? _selectedProviderType;

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
          });
        }
      } else {
        debugPrint('⚠️ Location is null - user may have denied permission');
      }
    } catch (e) {
      debugPrint('❌ Error getting country code: $e');
    }
  }

  Future<bool> _checkPhoneExists(String phone) async {
    try {
      final response =
          await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('phone', phone)
              .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking phone existence: $e');
      return false;
    }
  }

  Widget _buildPhoneFilter() {
    return IntlPhoneField(
      key: ValueKey(_userCountryCode ?? 'US'),
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.phone,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.primaryColor.withOpacity(0.05),
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

    // Check if phone number already exists
    setState(() => _isLoading = true);

    try {
      final phoneExists = await _checkPhoneExists(_userPhone!);
      if (phoneExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.phoneAlreadyRegistered,
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
    } catch (e) {
      debugPrint('Error checking phone: $e');
      // Continue with signup even if check fails
    }

    setState(() => _isLoading = true);

    try {
      // Prepare additional data for provider and carrenter roles
      Map<String, dynamic>? additionalData;
      if (_selectedRole == 'provider') {
        additionalData = {
          'business_name': _businessNameController.text.trim(),
          'provider_type': _selectedProviderType,
        };
      } else if (_selectedRole == 'carrenter') {
        additionalData = {'business_name': _businessNameController.text.trim()};
      }

      final response = await AuthService.signUpWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        countryCode: _userCountryCode!,
        phone: _userPhone!,
        password: _passwordController.text.trim(),
        role: _selectedRole,
        additionalData: additionalData,
      );

      if (response.user != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.accountCreatedSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to login screen
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.signupFailed} ${e.toString()}',
            ),
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom Header with Gradient and Logo
            Container(
              height: 280,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 40,
                    right: 16,
                    child: Consumer<LocaleProvider>(
                      builder: (context, localeProvider, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: PopupMenuButton<String>(
                            icon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.language,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  localeProvider.currentLocale.languageCode
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (String languageCode) {
                              localeProvider.setLocale(languageCode);
                            },
                            itemBuilder: (BuildContext context) {
                              return LocaleProvider.supportedLanguages.entries
                                  .map((entry) {
                                    return PopupMenuItem<String>(
                                      value: entry.key,
                                      child: Row(
                                        children: [
                                          Text(
                                            entry.key.toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(entry.value),
                                          if (localeProvider
                                                  .currentLocale
                                                  .languageCode ==
                                              entry.key) ...[
                                            const Spacer(),
                                            const Icon(
                                              Icons.check,
                                              color: AppTheme.primaryColor,
                                              size: 18,
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  })
                                  .toList();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/app/app_logo_without_background.png',
                              height: 100,
                              width: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.joinDrivio,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.createAccountSubtitle,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Role Selection Carousel
                    Text(
                      AppLocalizations.of(context)!.iWantToSignupAs,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _RoleCard(
                            title: AppLocalizations.of(context)!.passenger,
                            icon: Icons.person,
                            isSelected: _selectedRole == 'passenger',
                            onTap:
                                () =>
                                    setState(() => _selectedRole = 'passenger'),
                          ),
                          const SizedBox(width: 12),
                          _RoleCard(
                            title: AppLocalizations.of(context)!.driver,
                            icon: Icons.drive_eta,
                            isSelected: _selectedRole == 'driver',
                            onTap:
                                () => setState(() => _selectedRole = 'driver'),
                          ),
                          const SizedBox(width: 12),
                          _RoleCard(
                            title: AppLocalizations.of(context)!.provider,
                            icon: Icons.store,
                            isSelected: _selectedRole == 'provider',
                            onTap:
                                () =>
                                    setState(() => _selectedRole = 'provider'),
                          ),
                          const SizedBox(width: 12),
                          _RoleCard(
                            title: AppLocalizations.of(context)!.deliveryPerson,
                            icon: Icons.delivery_dining,
                            isSelected: _selectedRole == 'deliveryperson',
                            onTap:
                                () => setState(
                                  () => _selectedRole = 'deliveryperson',
                                ),
                          ),
                          const SizedBox(width: 12),
                          _RoleCard(
                            title: AppLocalizations.of(context)!.carRenter,
                            icon: Icons.car_rental,
                            isSelected: _selectedRole == 'carrenter',
                            onTap:
                                () =>
                                    setState(() => _selectedRole = 'carrenter'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fullName,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AppTheme.primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryColor.withOpacity(0.05),
                      ),
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.enterYourName;
                        }
                        if (value.trim().length < 2) {
                          return AppLocalizations.of(context)!.nameLengthError;
                        }
                        if (!RegExp(
                          r"^[a-zA-Z\s\-']+$",
                        ).hasMatch(value.trim())) {
                          return AppLocalizations.of(context)!.nameFormatError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    _buildPhoneFilter(),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.email,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppTheme.primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryColor.withOpacity(0.05),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.enterYourEmail;
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return AppLocalizations.of(context)!.invalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppTheme.primaryColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryColor.withOpacity(0.05),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.enterPassword;
                        }
                        if (value.length < 6) {
                          return AppLocalizations.of(
                            context,
                          )!.passwordLengthError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.confirmPassword,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppTheme.primaryColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(
                              () =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryColor.withOpacity(0.05),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(
                            context,
                          )!.confirmYourPassword;
                        }
                        if (value != _passwordController.text) {
                          return AppLocalizations.of(
                            context,
                          )!.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Provider-specific fields
                    if (_selectedRole == 'provider') ...[
                      TextFormField(
                        controller: _businessNameController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.businessName,
                          prefixIcon: const Icon(
                            Icons.business,
                            color: AppTheme.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.primaryColor.withOpacity(0.05),
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (_selectedRole == 'provider') {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(
                                context,
                              )!.enterBusinessName;
                            }
                            if (value.trim().length < 2) {
                              return AppLocalizations.of(
                                context,
                              )!.businessNameLengthError;
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedProviderType,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.providerType,
                          prefixIcon: const Icon(
                            Icons.category,
                            color: AppTheme.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.primaryColor.withOpacity(0.05),
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
                            return AppLocalizations.of(
                              context,
                            )!.selectProviderType;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Car Renter-specific fields
                    if (_selectedRole == 'carrenter') ...[
                      TextFormField(
                        controller: _businessNameController,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(
                                context,
                              )!.businessNameOptional,
                          hintText:
                              AppLocalizations.of(
                                context,
                              )!.carRentalBusinessNameHint,
                          prefixIcon: const Icon(
                            Icons.car_rental,
                            color: AppTheme.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.primaryColor.withOpacity(0.05),
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 32),

                    // Sign Up Button
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  AppLocalizations.of(context)!.createAccount,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Already have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.alreadyHaveAccount,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.login);
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            else
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
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
