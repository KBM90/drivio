import 'package:drivio_app/common/screens/login_screen.dart';
import 'package:drivio_app/common/screens/signup_screen.dart';
import 'package:drivio_app/common/screens/report_issue_screen.dart';
import 'package:drivio_app/car_renter/screens/carrenter_home_screen.dart';
import 'package:drivio_app/driver/ui/screens/driver_home_screen.dart';
import 'package:drivio_app/passenger/screens/passenger_home_screen.dart';
import 'package:drivio_app/passenger/screens/passenger_account_screen.dart';
import 'package:drivio_app/passenger/screens/passenger_activity_screen.dart';
import 'package:drivio_app/passenger/screens/passenger_services_screen.dart';
import 'package:drivio_app/passenger/screens/customer_delivery_tracking_screen.dart';
import 'package:drivio_app/provider/screens/provider_home_screen.dart';
import 'package:drivio_app/delivery_person/screens/delivery_person_home_screen.dart'; // Added import
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
  static const String deliveryPersonHome = '/deliveryPersonHome'; // Added route
  static const String customerDeliveryTracking = '/customer-delivery-tracking';
  static const String reportIssue = '/report-issue';

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
    deliveryPersonHome:
        (context) => const DeliveryPersonHomeScreen(), // Added builder
    reportIssue: (context) => const ReportIssueScreen(),
  };

  // Route handler for routes with arguments
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == customerDeliveryTracking) {
      final deliveryId = settings.arguments as int;
      return MaterialPageRoute(
        builder:
            (context) => CustomerDeliveryTrackingScreen(deliveryId: deliveryId),
      );
    }
    return null;
  }
}
