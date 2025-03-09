import 'package:flutter/material.dart';

class PreferencesButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PreferencesButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.tune, size: 24, color: Colors.black), // Preferences Icon
      onPressed: onPressed,
    );
  }
}
