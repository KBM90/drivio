import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AnimatedMapController {
  final MapController mapController;
  final TickerProvider vsync;

  AnimatedMapController({required this.mapController, required this.vsync});

  void animateMapMove({
    required LatLng destLocation,
    required double destZoom,
    required double destRotation,
  }) {
    // Create some variables
    final latTween = Tween<double>(
      begin: mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: mapController.camera.zoom,
      end: destZoom,
    );

    // Handle rotation wrapping (e.g. 350 -> 10 should stay close)
    double startRotation = mapController.camera.rotation;
    double endRotation = destRotation;

    // Normalize rotations to 0-360
    startRotation = startRotation % 360;
    if (startRotation < 0) startRotation += 360;

    endRotation = endRotation % 360;
    if (endRotation < 0) endRotation += 360;

    // Find shortest path
    double diff = endRotation - startRotation;
    if (diff > 180) endRotation -= 360;
    if (diff < -180) endRotation += 360;

    final rotateTween = Tween<double>(begin: startRotation, end: endRotation);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: vsync,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      mapController.moveAndRotate(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
        rotateTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }
}
