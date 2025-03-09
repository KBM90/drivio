import 'package:flutter/material.dart';
import 'package:drivio_app/passenger/screens/widgets/search_bar.dart';
import 'package:drivio_app/passenger/screens/widgets/bottom_nav_bar.dart';

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 40),
          SearchBarWidget(),
          Expanded(child: Center(child: Text("Passenger Home Screen"))),
        ],
      ),
      bottomNavigationBar: BottomNavBarWidget(),
    );
  }
}
