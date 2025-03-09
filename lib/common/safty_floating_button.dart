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
        onPressed: () {}, // show safty tools (call 911 , record /camera record)
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
}
