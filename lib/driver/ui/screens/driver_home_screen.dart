import 'package:drivio_app/common/widgets/safty_floating_button.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/providers/destination_provider.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/driver/ui/widgets/report_map_issue.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'driver_map_view.dart';
import '../widgets/menu_button.dart';
import '../widgets/search_destination_button.dart';
import '../widgets/status_bar.dart';

/*class DriverHomeScreen extends StatelessWidget {
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
}*/

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverProvider>(context, listen: false).getDriver(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final driver = driverProvider.currentDriver;
    return Scaffold(
      body: Stack(
        children: [
          // Show a loader
          MapView(), // Displays the map
          // Earnings Widget (Centered at the Top)
          /* Positioned(
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
          ),*/

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
            child: SearchDestinationButton(
              currentLocation:
                  driver?.location != null
                      ? LatLng(
                        driver!.location!.latitude!,
                        driver.location!.longitude!,
                      )
                      : null,
              onDestinationSelected: (destination, destinationName) {
                debugPrint(
                  '📍 Destination selected: $destinationName at $destination',
                );
                // Set destination in provider
                Provider.of<DestinationProvider>(
                  context,
                  listen: false,
                ).setDestination(destination, destinationName);
              },
            ),
          ),
          if (driver != null)
            if (driver.status == DriverStatus.active)
              Positioned(
                bottom: 125,
                left: 2, // Adjust left
                child: FloatingActionButton(
                  heroTag: "refresh",
                  onPressed: () async {
                    // Show loading (optional)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refreshing...')),
                    );

                    // Re-call initState-like refresh logic
                    await Provider.of<RideRequestsProvider>(
                      context,
                      listen: false,
                    ).getNearByRideRequests(
                      LatLng(
                        driver.location!.latitude!,
                        driver.location!.longitude!,
                      ),
                    ); // Add if method exists

                    // Optional: Refresh other providers (e.g., ride requests)

                    // Hide loading
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Refreshed!')),
                      );
                    }
                  },
                  backgroundColor: Colors.white,
                  elevation: 3,
                  mini: true,
                  shape: CircleBorder(),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
              ),
          if (driver != null) ReportMapIssue(driver: driver),
          if (driver?.status == DriverStatus.onTrip) SaftyFloatingButton(),
          if (driver?.status != DriverStatus.onTrip) StatusBar(),
        ],
      ),
    );
  }
}
