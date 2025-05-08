import 'package:drivio_app/auth/register_screen.dart';
import 'package:drivio_app/driver/ui/driver_home_screen.dart';
import 'package:drivio_app/auth/login_screen.dart';
import 'package:drivio_app/passenger/screens/home_screen.dart';
import 'package:drivio_app/passenger/screens/passenger_account_screen.dart';
import 'package:drivio_app/passenger/screens/passenger_activity_screen.dart';
import 'package:drivio_app/passenger/screens/passenger_services_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String driverHome = '/driverHome';
  static const String passengerHome = '/passengerHome';
  static const String passengerServices = '/passengerServices';
  static const String passengerActivity = '/passengerActivity';
  static const String passengerAccount = '/passengerAccount';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => LoginScreen(),
    register: (context) => RegisterScreen(),
    driverHome: (context) => DriverHomeScreen(),
    passengerHome: (context) => PassengerHomeScreen(),
    passengerServices: (context) => PassengerServicesScreen(),
    passengerActivity: (context) => PassengerActivityScreen(),
    passengerAccount: (context) => PassengerAccountScreen(),
  };
}
