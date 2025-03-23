import 'package:drivio_app/common/constants/routes.dart';
import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_status_provider.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/driver/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure async storage is ready
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? token = prefs.getString('auth_token');
  String? role = prefs.getString('role');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DriverStatusProvider()),
        ChangeNotifierProvider(create: (_) => DriverLocationProvider()),
        ChangeNotifierProvider(create: (_) => RideRequestsProvider()),
        ChangeNotifierProvider(
          create: (context) => WalletProvider()..fetchWallet(),
        ),
      ],
      child: MyApp(isLoggedIn: token != null, role: role),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;

  const MyApp({super.key, required this.isLoggedIn, required this.role});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: _getInitialRoute(),
      routes: AppRoutes.routes,
    );
  }

  String _getInitialRoute() {
    if (isLoggedIn) {
      if (role == 'driver') return AppRoutes.driverHome;
      if (role == 'passenger') return AppRoutes.passengerHome;
    }
    return AppRoutes.login;
  }
}
