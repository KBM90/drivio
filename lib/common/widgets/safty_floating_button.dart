import 'package:drivio_app/driver/providers/crash_report_provider.dart';
import 'package:drivio_app/driver/providers/location_sharing_provider.dart';
import 'package:drivio_app/driver/providers/ride_recording_provider.dart';
import 'package:drivio_app/driver/ui/screens/crash_report_screen.dart';
import 'package:drivio_app/driver/ui/screens/location_sharing_screen.dart';
import 'package:drivio_app/driver/ui/screens/ride_recording_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SaftyFloatingButton extends StatelessWidget {
  const SaftyFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top:
          MediaQuery.of(context).padding.top +
          MediaQuery.of(context).size.height *
              0.1, // SafeArea + 2% of screen height
      left: MediaQuery.of(context).size.width * 0.05, // Adjust left
      child: FloatingActionButton(
        heroTag: "safty",
        onPressed: () {
          _showSafetyToolkit(context);
        }, // Show safety tools
        backgroundColor: Colors.white,
        elevation: 3,
        mini: true,
        shape: CircleBorder(),
        child: Icon(
          Icons.security, // Shield icon
          color: Colors.blue,
          size: 20,
        ),
      ),
    );
  }

  void _showSafetyToolkit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Allows full-screen modal if needed
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6, // Adjust height as needed
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              // Prevents overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.videocam),
                    title: Text("Record My Ride"),
                    subtitle: Text(
                      "Record your trips with your phone or dashcam",
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChangeNotifierProvider(
                                  create: (_) => RideRecordingProvider(),
                                  child: RideRecordingScreen(),
                                ),
                          ),
                        );
                      },
                      child: Text("Set up"),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.share_location),
                    title: Text("Follow My Ride"),
                    subtitle: Text(
                      "Share location and trip status with family and friends",
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChangeNotifierProvider(
                                  create: (_) => LocationSharingProvider(),
                                  child: LocationSharingScreen(),
                                ),
                          ),
                        );
                      },
                      child: Text("Send"),
                    ),
                  ),

                  ListTile(
                    leading: Icon(Icons.report, color: Colors.red),
                    title: Text("Report a crash"),
                    subtitle: Text(
                      "Report an accident with photos and details",
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChangeNotifierProvider(
                                  create: (_) => CrashReportProvider(),
                                  child: CrashReportScreen(),
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                      child: Text("Report"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
