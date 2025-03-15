import 'package:drivio_app/common/widgets/safty_floating_button.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:flutter/material.dart';
import '../../common/widgets/map_view.dart';
import 'widgets/earnings_widget.dart';
import 'widgets/menu_button.dart';
import '../../common/widgets/search_button.dart';
import 'widgets/status_bar.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  Driver? _currentDriver;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final driver = await DriverService.getDriver();
    setState(() {
      _currentDriver = driver;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapView(driver: _currentDriver), // Displays the map
          // Earnings Widget (Centered at the Top)
          Positioned(
            top: 40,
            left: MediaQuery.of(context).size.width / 2 - 300,
            right: MediaQuery.of(context).size.width / 2 - 300, // Centered
            child: EarningsWidget(),
          ),

          // Menu Button (Left Side)
          Positioned(top: 40, left: 20, child: MenuButton()),

          // Search Button (Right Side)
          Positioned(top: 40, right: 20, child: SearchButton()),

          SaftyFloatingButton(),
          StatusBar(),
        ],
      ),
    );
  }
}
