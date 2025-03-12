import 'package:drivio_app/driver/screens/modals/preferences_modal_screen.dart';
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
        _showPreferencesModal(context);
      },
    );
  }

  void _showPreferencesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows full height
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const PreferencesModal();
      },
    );
  }
}
