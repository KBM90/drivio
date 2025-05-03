import 'package:drivio_app/common/models/map_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapUtilities {
  List<Polyline> drawPolylines(List<MapReport> reports) {
    //  print(reports);
    return reports
        .where(
          (report) => report.routePoints != null,
        ) // First filter out null routes
        .map((report) {
          // Safely process points with null checks
          // print(report.routePoints!.first.latitude);
          final validPoints =
              report.routePoints!
                  .where(
                    (point) =>
                        point.latitude != null && point.longitude != null,
                  )
                  .map((point) => LatLng(point.latitude!, point.longitude!))
                  .toList();

          return Polyline(
            points: validPoints,
            color: const Color.fromARGB(132, 250, 4, 4),
            strokeWidth: 14.0,
          );
        })
        .where(
          (polyline) => polyline.points.isNotEmpty,
        ) // Filter out empty polylines
        .toList();
  }

  List<Marker> putMarkers(List<MapReport> reports) {
    return reports.map((report) {
      final iconColor = _getIconColorForReportType(report.reportType);

      return Marker(
        point: LatLng(
          report.pointLocation!.latitude!,
          report.pointLocation!.longitude!,
        ),
        width: 40,
        height: 40,
        child: Icon(
          _getIconForReportType(report.reportType),
          color: iconColor,
          size: 30,
        ),
      );
    }).toList();
  }

  Color _getIconColorForReportType(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return const Color.fromARGB(255, 223, 8, 11);
      case 'traffic':
        return const Color.fromARGB(255, 223, 8, 11);
      case 'wrong directions':
        return const Color.fromARGB(255, 223, 8, 11);
      case 'closure':
        return const Color.fromARGB(255, 223, 8, 11);
      case 'radar':
        return const Color.fromARGB(255, 223, 8, 11);
      default:
        return const Color.fromARGB(255, 223, 8, 11);
    }
  }

  IconData _getIconForReportType(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return Icons.car_crash;
      case 'traffic':
        return Icons.traffic;
      case 'wrong directions':
        return Icons.directions_off;
      case 'closure':
        return Icons.block_outlined;
      case 'radar':
        return Icons.emergency_recording_rounded;
      default:
        return Icons.report;
    }
  }
}
