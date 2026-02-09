import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A widget that rotates its child based on a heading.
/// Useful for showing direction on a map.
class NavigationMarker extends StatelessWidget {
  /// The heading in degrees (0 = North, 90 = East, etc.)
  final double heading;

  /// The size of the icon
  final double size;

  /// The color of the icon
  final Color color;

  /// Optional child widget to rotate. Defaults to Icons.navigation.
  final Widget? child;

  const NavigationMarker({
    super.key,
    required this.heading,
    this.size = 30,
    this.color = Colors.blue,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Convert degrees to radians
    final angle = heading * (math.pi / 180);

    return Transform.rotate(
      angle: angle,
      child: child ?? Icon(Icons.navigation, color: color, size: size),
    );
  }
}
