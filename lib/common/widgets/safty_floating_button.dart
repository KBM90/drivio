import 'package:flutter/material.dart';

class SaftyFloatingButton extends StatelessWidget {
  const SaftyFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 2, // Adjust left
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
                      onPressed: () {},
                      child: Text("Set up"),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.wifi),
                    title: Text("Follow My Ride"),
                    subtitle: Text(
                      "Share location and trip status with family and friends",
                    ),
                    trailing: TextButton(
                      onPressed: () {},
                      child: Text("Set up"),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.check_circle),
                    title: Text("Proof of Trip Status"),
                    subtitle: Text(
                      "Show law enforcement your current trip status",
                    ),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.report),
                    title: Text("Report a crash"),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.call),
                    title: Text("911 Assistance"),
                    onTap: () {},
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
