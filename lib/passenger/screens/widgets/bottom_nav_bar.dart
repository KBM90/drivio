import 'package:flutter/material.dart';

class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.apps), label: "Services"),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Activity"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
      ],
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
    );
  }
}
