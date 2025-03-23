import 'package:drivio_app/driver/ui/modals/side_menu.dart';
import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
        icon: Icon(Icons.menu, color: Colors.black),
        onPressed: () {
          _showSideMenu(context);
        },
      ),
    );
  }

  void _showSideMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Side Menu",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width:
                MediaQuery.of(context).size.width * 0.75, // 75% of screen width
            child: SideMenu(),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0), // Start off-screen to the left
            end: Offset.zero, // Slide in
          ).animate(animation),
          child: child,
        );
      },
    );
  }
}
