import 'package:flutter/material.dart';

class RecommandedForYouButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RecommandedForYouButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.menu, size: 24, color: Colors.black), // Toggle Icon
      onPressed: onPressed,
    );
  }
}
