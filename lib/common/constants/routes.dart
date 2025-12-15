import 'package:drivio_app/common/screens/login_screen.dart';
import 'package:drivio_app/common/screens/signup_screen.dart';
import 'package:drivio_app/car_renter/screens/carrenter_home_screen.dart';
import 'package:drivio_app/driver/ui/screens/driver_home_screen.dart';
import 'package:drivio_app/passenger/screens/passenger_home_screen.dart';
import 'package:drivio_app/passenger/screens/passenger_account_screen.dart';
import 'package:drivio_app/passenger/screens/passenger_activity_screen.dart';
import 'package:drivio_app/passenger/screens/passenger_services_screen.dart';
import 'package:drivio_app/provider/screens/provider_home_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String driverHome = '/driverHome';
  static const String passengerHome = '/passengerHome';
  static const String providerHome = '/providerHome';
  static const String carRenterHome = '/carRenterHome';
  static const String passengerServices = '/passengerServices';
  static const String passengerActivity = '/passengerActivity';
  static const String passengerAccount = '/passengerAccount';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => LoginScreen(),
    signup: (context) => SignUpScreen(),
    driverHome: (context) => DriverHomeScreen(),
    passengerHome: (context) => PassengerHomeScreen(),
    providerHome: (context) => const ProviderHomeScreen(),
    carRenterHome: (context) => const CarRenterHomeScreen(),
    passengerServices: (context) => PassengerServicesScreen(),
    passengerActivity: (context) => PassengerActivityScreen(),
    passengerAccount: (context) => PassengerAccountScreen(),
  };
}
