import 'package:drivio_app/driver/screens/driver_home_screen.dart';
import 'package:drivio_app/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      home: LoginScreen(),
      initialRoute: '/login', // Set the first screen
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => DriverHomeScreen(),
      }, // Choose user role
    );
  }
}
