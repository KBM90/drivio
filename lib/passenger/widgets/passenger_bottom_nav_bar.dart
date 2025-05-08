import 'package:flutter/material.dart';
import 'package:drivio_app/common/constants/routes.dart';

class PassengerBottomNavBarWidget extends StatelessWidget {
  const PassengerBottomNavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // figure out which tab we’re on right now
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    int currentIndex;
    switch (currentRoute) {
      case AppRoutes.passengerHome:
        currentIndex = 0;
        break;
      case AppRoutes.passengerServices:
        currentIndex = 1;
        break;
      case AppRoutes.passengerActivity: // you’ll need to add these to AppRoutes
        currentIndex = 2;
        break;
      case AppRoutes.passengerAccount:
        currentIndex = 3;
        break;
      default:
        currentIndex = 0;
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.apps), label: "Services"),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Activity"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
      ],
      onTap: (index) {
        String targetRoute;
        switch (index) {
          case 0:
            targetRoute = AppRoutes.passengerHome;
            break;
          case 1:
            targetRoute = AppRoutes.passengerServices;
            break;
          case 2:
            targetRoute = AppRoutes.passengerActivity;
            break;
          case 3:
            targetRoute = AppRoutes.passengerAccount;
            break;
          default:
            return;
        }

        // don’t re‐push if we’re already there
        if (targetRoute != currentRoute) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            targetRoute,
            (route) => false,
          );
        }
      },
    );
  }
}
