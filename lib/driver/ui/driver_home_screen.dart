import 'package:drivio_app/common/widgets/safty_floating_button.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/providers/wallet_provider.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _loadCurrentDriver();
    _loadWallet();
  }

  Future<void> _loadCurrentDriver() async {
    final driver = await DriverService.getDriver();

    setState(() {
      _currentDriver = driver;
    });
  }

  Future<void> _loadWallet() async {
    await Provider.of<WalletProvider>(context, listen: false).fetchWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _currentDriver == null
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Show a loader
              : MapView(driver: _currentDriver), // Displays the map
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
