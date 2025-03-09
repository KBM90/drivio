import 'package:drivio_app/driver/screens/widgets/preferences_button.dart';
import 'package:drivio_app/driver/screens/widgets/recommanded_for_you_button.dart';
import 'package:drivio_app/driver/screens/widgets/safty_floating_button.dart';
import 'package:flutter/material.dart';
import 'widgets/map_view.dart';
import 'widgets/earnings_widget.dart';
import 'widgets/menu_button.dart';
import 'widgets/search_button.dart';
import 'widgets/status_bar.dart';
import 'widgets/go_floating_buttons.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapView(), // Displays the map
          // Earnings Widget (Centered at the Top)
          Positioned(
            top: 40,
            left: MediaQuery.of(context).size.width / 2 - 40, // Centered
            child: EarningsWidget(),
          ),

          // Menu Button (Left Side)
          Positioned(
            top: 40,
            left: 20,
            child: MenuButton(
              onPressed: () {
                print("Menu button clicked");
              },
            ),
          ),

          // Search Button (Right Side)
          Positioned(
            top: 40,
            right: 20,
            child: SearchButton(
              onPressed: () {
                print("Search button clicked");
              },
            ),
          ),

          // Status Bar at the Bottom
          //  Positioned(bottom: 0, left: 0, right: 0, child: StatusBar()),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PreferencesButton(
                    onPressed: () {
                      print("Preferences clicked");
                    },
                  ),
                  StatusBar(),
                  RecommandedForYouButton(
                    onPressed: () {
                      print("Toggle clicked");
                    },
                  ),
                ],
              ),
            ),
          ),
          SaftyFloatingButton(),
          // Floating GO Button (Make sure it's positioned correctly)
          GoFloatingButtons(),
        ],
      ),
    );
  }
}
