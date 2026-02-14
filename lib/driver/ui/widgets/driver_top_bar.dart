import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/ui/modals/side_menu.dart';
import 'package:drivio_app/driver/ui/widgets/search_destination_button.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class DriverTopBar extends StatelessWidget {
  final LatLng? currentLocation;
  final Function(LatLng destination, String destinationName)?
  onDestinationSelected;

  const DriverTopBar({
    super.key,
    this.currentLocation,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Menu Button
            InkWell(
              onTap: () => _showSideMenu(context),
              child: const Icon(Icons.menu, color: Colors.black87),
            ),

            Expanded(
              child: InkWell(
                onTap: () {
                  _showSearchModal(context);
                },
                child: Consumer<DriverProvider>(
                  builder: (context, driverProvider, child) {
                    final status =
                        driverProvider.currentDriver?.status ??
                        DriverStatus.inactive;
                    final isOnline =
                        status == DriverStatus.active ||
                        status == DriverStatus.onTrip;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline ? "You're Online" : "You're Offline",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Search Button
            InkWell(
              onTap: () => _showSearchModal(context),
              child: const Icon(Icons.search, color: Colors.blueAccent),
            ),
          ],
        ),
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
            width: MediaQuery.of(context).size.width * 0.75,
            child: SideMenu(),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SearchDestinationModal(
          onDestinationSelected: onDestinationSelected,
          currentLocation: currentLocation,
        );
      },
    );
  }
}
