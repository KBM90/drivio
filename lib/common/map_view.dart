import 'package:drivio_app/driver/utils/map_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:drivio_app/helpers/geolocator_helper.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;

  /// Fetch user location and update the map
  Future<void> _updateLocation() async {
    LatLng? location = await GeolocatorHelper.getCurrentLocation();
    if (location == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unable to get location.")));
      return;
    }

    setState(() {
      _currentLocation = location;
    });

    _mapController.move(location, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
            initialCenter: LatLng(37.7749, -122.4194), // Default: San Francisco
            initialZoom: 13,
          ),
          children: [
            TileLayer(urlTemplate: MapConstants.tileLayerUrl),
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.car_crash, color: Colors.red, size: 40),
                  ),
                ],
              ),
          ],
        ),

        /// GPS Button (Bottom Right)
        Positioned(
          bottom: 80,
          right: 2,
          child: FloatingActionButton(
            onPressed: _updateLocation,
            backgroundColor: Colors.white,
            elevation: 3,
            mini: true,
            shape: CircleBorder(),
            child: Icon(Icons.my_location, color: Colors.black, size: 20),
          ),
        ),
      ],
    );
  }
}
