import 'package:flutter/material.dart';

class GoFloatingButtons extends StatelessWidget {
  const GoFloatingButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          heroTag: "go_button", // Unique hero tag
          onPressed: () {}, // Go Online Action
          backgroundColor: Colors.blue,
          elevation: 3,
          shape: CircleBorder(),
          child: Text(
            "GO",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
