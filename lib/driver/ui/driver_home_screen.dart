import 'package:drivio_app/common/providers/map_reports_provider.dart';
import 'package:drivio_app/common/widgets/safty_floating_button.dart';
import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/providers/passenger_provider.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/driver/providers/wallet_provider.dart';
import 'package:drivio_app/driver/ui/widgets/report_map_issue.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/map_view.dart';
import 'widgets/earnings_widget.dart';
import 'widgets/menu_button.dart';
import '../../common/widgets/search_button.dart';
import 'widgets/status_bar.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DriverLocationProvider()),
        ChangeNotifierProvider(create: (_) => RideRequestsProvider()),
        ChangeNotifierProvider(create: (context) => WalletProvider()),
        ChangeNotifierProvider(create: (context) => DriverProvider()),
        ChangeNotifierProvider(create: (context) => PassengerProvider()),
        ChangeNotifierProvider(create: (context) => MapReportsProvider()),
      ],
      child: DriverHomeScreenwidget(),
    );
  }
}

class DriverHomeScreenwidget extends StatefulWidget {
  const DriverHomeScreenwidget({super.key});

  @override
  State<DriverHomeScreenwidget> createState() => _DriverHomeScreenWidgetState();
}

class _DriverHomeScreenWidgetState extends State<DriverHomeScreenwidget> {
  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    await Provider.of<WalletProvider>(context, listen: false).fetchWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Show a loader
          MapView(), // Displays the map
          // Earnings Widget (Centered at the Top)
          Positioned(
            top:
                MediaQuery.of(context).size.height *
                0.05, // 5% of screen height
            left: 0,
            right: 0,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.9, // 90% of screen width
                child: EarningsWidget(),
              ),
            ),
          ),

          // MenuButton (Top-Left, Responsive Padding)
          Positioned(
            top:
                MediaQuery.of(context).padding.top +
                MediaQuery.of(context).size.height *
                    0.02, // SafeArea + 2% of screen height
            left:
                MediaQuery.of(context).size.width * 0.05, // 5% of screen width
            child: MenuButton(),
          ),

          // Search Button (Right Side)
          Positioned(
            top:
                MediaQuery.of(context).padding.top +
                MediaQuery.of(context).size.height *
                    0.02, // SafeArea + 2% of screen height
            right:
                MediaQuery.of(context).size.width * 0.05, // 5% of screen width
            child: SearchButton(),
          ),
          ReportMapIssue(),
          SaftyFloatingButton(),
          StatusBar(),
        ],
      ),
    );
  }
}
