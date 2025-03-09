import 'package:flutter/material.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),

      child: Center(
        child: Text("You're offline", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
