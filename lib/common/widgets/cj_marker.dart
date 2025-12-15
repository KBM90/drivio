// lib/common/widgets/cj_marker.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class CJMarker extends StatefulWidget {
  final double rotation;

  const CJMarker({super.key, this.rotation = 0});

  @override
  State<CJMarker> createState() => _CJMarkerState();
}

class _CJMarkerState extends State<CJMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Radar sweep effect
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(70, 70),
                painter: RadarPainter(
                  color: const Color(0xFF00FF00).withOpacity(0.3),
                ),
              ),
            );
          },
        ),
        // Pulsing outer ring
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pulse = (_controller.value * 2) % 1.0;
            return Container(
              width: 50 + (pulse * 25),
              height: 50 + (pulse * 25),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00FF00).withOpacity(1 - pulse),
                  width: 2,
                ),
              ),
            );
          },
        ),
        // Main CJ icon
        Transform.rotate(
          angle: widget.rotation,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF00FF00),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.navigation, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}

class RadarPainter extends CustomPainter {
  final Color color;

  RadarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path =
        Path()
          ..moveTo(size.width / 2, size.height / 2)
          ..lineTo(size.width / 2, 0)
          ..arcTo(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width / 2,
            ),
            -math.pi / 2,
            math.pi / 3,
            false,
          )
          ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
