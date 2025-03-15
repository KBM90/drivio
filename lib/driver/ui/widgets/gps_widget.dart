import 'package:flutter/material.dart';

class GPSWidget extends StatelessWidget {
  const GPSWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {},
      backgroundColor: Colors.white,
      elevation: 3,
      mini: true,
      shape: CircleBorder(),
      child: Icon(Icons.my_location, color: Colors.black, size: 20),
    );
  }
}
