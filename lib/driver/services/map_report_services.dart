import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:drivio_app/common/models/map_report.dart';
import 'package:drivio_app/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapReportService {
  // Function to submit a map report
  static Future<bool> submitReport({
    required String reportType,
    LatLng? point, // Single point
    List<LatLng>? path, // Route points
    String? description,
  }) async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) {
        throw Exception('User not found');
      }

      final Map<String, dynamic> data = {
        'report_type': reportType,
        'user_id': userId,
        'description': description ?? 'Reported via map',
        'status': 'Active',
      };

      if (point != null) {
        data['point_location'] = 'POINT(${point.longitude} ${point.latitude})';
      }

      if (path != null && path.isNotEmpty) {
        data['route_points'] =
            path
                .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
                .toList();
      }

      await Supabase.instance.client.from('map_reports').insert(data);

      return true;
    } catch (e) {
      debugPrint('Error submitting report: $e');
      return false;
    }
  }

  static Future<List<MapReport>> getReportsWithinRadius() async {
    try {
      final LatLng? driverLocation =
          await GeolocatorHelper.getCurrentLocation();
      if (driverLocation == null) {
        throw Exception('Unable to get driver location');
      }

      // Fetch all active reports
      final response = await Supabase.instance.client
          .from('map_reports')
          .select()
          .eq('status', 'Active');

      final List<MapReport> reports =
          (response as List).map((json) => MapReport.fromJson(json)).toList();

      // Filter by radius (e.g., 50km)
      const double radiusInMeters = 50000;
      final List<MapReport> nearbyReports = [];

      for (var report in reports) {
        if (report.pointLocation != null &&
            report.pointLocation!.latitude != null &&
            report.pointLocation!.longitude != null) {
          final double distance = Geolocator.distanceBetween(
            driverLocation.latitude,
            driverLocation.longitude,
            report.pointLocation!.latitude!,
            report.pointLocation!.longitude!,
          );

          if (distance <= radiusInMeters) {
            nearbyReports.add(report);
          }
        }
      }

      return nearbyReports;
    } catch (e) {
      debugPrint('Error in getReportsWithinRadius: $e');
      rethrow;
    }
  }

  static Future<List<MapReport>> getUserMapReports() async {
    final token = await SharedPreferencesHelper().getValue<String>(
      'auth_token',
    );
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    final url = Uri.parse(ApiConfig.getUserReportsUrl);
    final headers = ApiConfig.getAuthHeaders(token);

    try {
      final response = await http.get(url, headers: headers);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          final List<dynamic> reportsJson = responseData['data'];
          return reportsJson.map((json) => MapReport.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch reports');
        }
      } else {
        throw Exception('Server responded with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getReportsWithinRadius: $e');
      rethrow;
    }
  }
}
