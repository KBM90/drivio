import 'package:flutter/material.dart';

class RefreshScreenButton extends StatelessWidget {
  const RefreshScreenButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 125,
      left: 2, // Adjust left
      child: FloatingActionButton(
        heroTag: "refresh",
        onPressed: () {
          // This pops the current route, effectively "refreshing" by returning to the previous screen
          // (Assume the previous screen rebuilds or refreshes data on pop)
          Navigator.pop(context, "refresh");
        }, // Show safety tools
        backgroundColor: Colors.white,
        elevation: 3,
        mini: true,
        shape: CircleBorder(),
        child: Icon(
          Icons.refresh, // Shield icon
          color: Colors.blue,
          size: 20,
        ),
      ),
    );
  }
}
