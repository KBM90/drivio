import 'package:drivio_app/common/constants/routes.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check once whether we have a stored "role" key.
  final bool isLoggedIn = await SharedPreferencesHelper.containsKey('role');

  // If logged in, pull the role; otherwise leave it null.
  final String? role =
      isLoggedIn
          ? await SharedPreferencesHelper().getValue<String>('role')
          : null;

  runApp(MyApp(isLoggedIn: isLoggedIn, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;

  const MyApp({super.key, required this.isLoggedIn, required this.role});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: _getInitialRoute(),
      routes: AppRoutes.routes,
    );
  }

  String _getInitialRoute() {
    if (isLoggedIn && role != null) {
      if (role == 'driver') return AppRoutes.driverHome;
      if (role == 'passenger') return AppRoutes.passengerHome;
    }
    return AppRoutes.login;
  }
}
