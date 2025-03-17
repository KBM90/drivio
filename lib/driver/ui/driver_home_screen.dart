import 'package:drivio_app/common/widgets/safty_floating_button.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/models/wallet.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:drivio_app/driver/services/wallet_service.dart';
import 'package:drivio_app/driver/ui/screens/wallet_page.dart';
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
  Wallet? _currentWallet;

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

  Future<void> _loadWallet() async {
    final wallet = await WalletService().getWallet();
    setState(() {
      _currentWallet = wallet;
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
            child: EarningsWidget(wallet: _currentWallet),
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
