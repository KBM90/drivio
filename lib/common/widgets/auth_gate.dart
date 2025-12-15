import 'package:drivio_app/common/constants/routes.dart';
import 'package:drivio_app/common/providers/device_location_provider.dart';
import 'package:drivio_app/common/providers/map_reports_provider.dart';
import 'package:drivio_app/common/screens/banned_user_screen.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/common/services/notification_service.dart';
import 'package:drivio_app/common/providers/notification_provider.dart';
import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/providers/destination_provider.dart';
import 'package:drivio_app/driver/providers/driver_passenger_provider.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/passenger/providers/passenger_provider.dart';
import 'package:drivio_app/passenger/providers/passenger_ride_request_provider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _userRole;
  bool _isLoading = true;
  bool _isBanned = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRole();
  }

  Future<void> _checkAuthAndRole() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        // Check if token is expired (or close to expiring)
        if (session.isExpired) {
          debugPrint('⚠️ Session expired, attempting refresh...');
          try {
            await Supabase.instance.client.auth.refreshSession();
            debugPrint('✅ Session refreshed successfully');
          } catch (e) {
            debugPrint('❌ Session refresh failed: $e');
            await AuthService.signOut();
            if (mounted) {
              setState(() {
                _userRole = null;
                _isLoading = false;
              });
            }
            return;
          }
        }

        // Initialize notifications
        await NotificationService.initialize();

        // Check if user is banned
        final isBanned = await AuthService.isUserBanned();
        if (isBanned) {
          if (mounted) {
            setState(() {
              _isBanned = true;
              _isLoading = false;
            });
          }
          return;
        }

        final role = await AuthService.getUserRole();
        if (mounted) {
          setState(() {
            _userRole = role;
            _isBanned = false;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _userRole = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking auth: $e');
      // If any error occurs during auth check, sign out to be safe
      await AuthService.signOut();
      if (mounted) {
        setState(() {
          _userRole = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // ✅ Use WidgetsBinding.addPostFrameCallback to schedule setState after build
        if (snapshot.hasData) {
          final event = snapshot.data!.event;

          if (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed) {
            // Schedule the update AFTER the current build completes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _checkAuthAndRole();
              }
            });
          } else if (event == AuthChangeEvent.signedOut) {
            // Schedule the update AFTER the current build completes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _userRole = null;
                  _isLoading = false;
                });
              }
            });
          }
        }

        // Show loading while checking auth state
        if (_isLoading || snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        // User is not logged in
        if (session == null) {
          return AppRoutes.routes[AppRoutes.login]!(context);
        }

        // User is banned - show banned screen
        if (_isBanned) {
          return const BannedUserScreen();
        }

        // User is logged in - wrap with providers based on role
        if (_userRole == 'driver') {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => DriverLocationProvider()),
              ChangeNotifierProvider(create: (_) => RideRequestsProvider()),
              ChangeNotifierProvider(create: (_) => DriverProvider()),
              ChangeNotifierProvider(create: (_) => DestinationProvider()),
              ChangeNotifierProvider(create: (_) => DriverPassengerProvider()),
              ChangeNotifierProvider(create: (_) => MapReportsProvider()),
              ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ],
            child: _AppNavigator(initialRoute: AppRoutes.driverHome),
          );
        } else if (_userRole == 'passenger') {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => PassengerRideRequestProvider(),
              ),
              ChangeNotifierProvider(create: (context) => PassengerProvider()),

              ChangeNotifierProvider(
                create: (context) => DeviceLocationProvider(),
              ),
              ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ],
            child: _AppNavigator(initialRoute: AppRoutes.passengerHome),
          );
        } else if (_userRole == 'provider') {
          return const _AppNavigator(initialRoute: AppRoutes.providerHome);
        } else if (_userRole == 'carrenter') {
          return const _AppNavigator(initialRoute: AppRoutes.carRenterHome);
        } else {
          // Role not loaded yet or invalid
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error: Could not determine user role.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await AuthService.signOut();
                      if (context.mounted) {
                        setState(() {
                          _userRole = null;
                          _isLoading = false;
                        });
                      }
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

// Navigator widget that provides access to all routes
class _AppNavigator extends StatelessWidget {
  final String initialRoute;

  const _AppNavigator({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        final routeName = settings.name ?? initialRoute;
        final routeBuilder = AppRoutes.routes[routeName];

        if (routeBuilder != null) {
          return MaterialPageRoute(builder: routeBuilder, settings: settings);
        }

        // Fallback to initial route if route not found
        return MaterialPageRoute(
          builder: AppRoutes.routes[initialRoute]!,
          settings: settings,
        );
      },
    );
  }
}
