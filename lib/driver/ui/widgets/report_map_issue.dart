import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/ui/screens/report_map.dart';
import 'package:drivio_app/driver/ui/screens/user_map_reports_screen.dart';
import 'package:flutter/material.dart';

class ReportMapIssue extends StatelessWidget {
  final Driver driver;
  const ReportMapIssue({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top:
          MediaQuery.of(context).padding.top +
          MediaQuery.of(context).size.height *
              0.2, // SafeArea + 2% of screen height
      left: MediaQuery.of(context).size.width * 0.05,
      child: FloatingActionButton(
        heroTag: "report_map_issue",
        onPressed: () {
          _showReportToolkit(context);
        }, // Show safety tools
        backgroundColor: Colors.white,
        elevation: 3,
        mini: true,
        shape: CircleBorder(),
        child: Icon(
          Icons.flag_circle, // Shield icon
          color: const Color.fromARGB(255, 248, 1, 1),
          size: 40,
        ),
      ),
    );
  }

  void _showReportToolkit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take only the space needed
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report a map issue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.grey),
                    onPressed: () {
                      Navigator.pop(context); // Close the bottom sheet
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Report Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReportOption(
                    context,
                    icon: Icons.traffic,
                    label: 'Traffic',
                    onTap: () {
                      // Handle Traffic report
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ReportMap(
                                reportType: 'Traffic',
                                driver: driver,
                              ),
                        ),
                      );
                    },
                  ),
                  _buildReportOption(
                    context,
                    icon: Icons.car_crash,
                    label: 'accident',
                    onTap: () {
                      // Handle Accident report
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ReportMap(
                                reportType: 'Accident',
                                driver: driver,
                              ),
                        ),
                      );
                    },
                  ),
                  _buildReportOption(
                    context,
                    icon: Icons.block,
                    label: 'Closure',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ReportMap(
                                reportType: 'Closure',
                                driver: driver,
                              ),
                        ),
                      );
                    },
                  ),

                  _buildReportOption(
                    context,
                    icon: Icons.emergency_recording,
                    label: 'Speed Radar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ReportMap(
                                reportType: 'Radar',
                                driver: driver,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Wrong Directions Option (Separate Row)
              _buildReportOption(
                context,
                icon: Icons.directions_off,
                label: 'Wrong directions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ReportMap(
                            reportType: 'Wrong Directions',
                            driver: driver,
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // My Reports Link
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: UserReportsScreen(reports: []),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.report, color: Colors.black),
                label: const Text(
                  'My reports',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(
              icon,
              size: 30,
              color: label == 'Closure' ? Colors.red : Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
