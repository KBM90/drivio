import 'package:drivio_app/driver/ui/screens/preferences_page.dart';
import 'package:flutter/material.dart';

class PreferencesButton extends StatelessWidget {
  const PreferencesButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.tune,
        size: 24,
        color: Colors.black,
      ), // Preferences Icon
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PreferencesScreen()),
        );
      },
    );
  }
}
