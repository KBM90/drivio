import 'dart:io';
import 'package:drivio_app/common/models/crash_report.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class CrashReportService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  /// Get current location with address
  Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // For now, return position without reverse geocoding
      // You can add reverse geocoding service later if needed
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': null, // Can be populated with reverse geocoding
      };
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Upload photo to Supabase Storage
  Future<String?> uploadPhoto(File photoFile, String crashId) async {
    try {
      final fileName =
          '${crashId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'crash_reports/$crashId/$fileName';

      await _supabase.storage
          .from('crash-photos')
          .upload(
            filePath,
            photoFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('crash-photos')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  /// Submit crash report to database
  Future<CrashReport?> submitCrashReport({
    required CrashSeverity severity,
    required double latitude,
    required double longitude,
    String? address,
    String? description,
    bool injuriesReported = false,
    int vehiclesInvolved = 1,
    bool policeNotified = false,
    List<String> photos = const [],
    List<String> emergencyContacted = const [],
    int? rideId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final crashId = _uuid.v4();
      final now = DateTime.now();

      final crashData = {
        'id': crashId,
        'user_id': userId,
        'ride_id': rideId,
        'severity': severity.name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'description': description,
        'injuries_reported': injuriesReported,
        'vehicles_involved': vehiclesInvolved,
        'police_notified': policeNotified,
        'photos': photos,
        'emergency_contacted': emergencyContacted,
        'created_at': now.toIso8601String(),
      };

      await _supabase.from('crash_reports').insert(crashData);

      return CrashReport(
        id: crashId,
        userId: userId,
        rideId: rideId,
        severity: severity,
        latitude: latitude,
        longitude: longitude,
        address: address,
        description: description,
        injuriesReported: injuriesReported,
        vehiclesInvolved: vehiclesInvolved,
        policeNotified: policeNotified,
        photos: photos,
        emergencyContacted: emergencyContacted,
        createdAt: now,
      );
    } catch (e) {
      print('Error submitting crash report: $e');
      return null;
    }
  }

  /// Fetch user's crash reports
  Future<List<CrashReport>> getUserCrashReports() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('crash_reports')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CrashReport.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching crash reports: $e');
      return [];
    }
  }

  /// Delete crash report
  Future<bool> deleteCrashReport(String crashId) async {
    try {
      await _supabase.from('crash_reports').delete().eq('id', crashId);

      // Also delete photos from storage
      try {
        await _supabase.storage.from('crash-photos').remove([
          'crash_reports/$crashId',
        ]);
      } catch (e) {
        print('Error deleting photos: $e');
      }

      return true;
    } catch (e) {
      print('Error deleting crash report: $e');
      return false;
    }
  }

  /// Dial emergency number
  Future<bool> dialEmergency(String number) async {
    try {
      final uri = Uri.parse('tel:$number');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      print('Error dialing emergency: $e');
      return false;
    }
  }

  /// Dial 911
  Future<bool> dial911() => dialEmergency('911');

  /// Dial police
  Future<bool> dialPolice() =>
      dialEmergency('911'); // Can be customized per region

  /// Dial ambulance
  Future<bool> dialAmbulance() =>
      dialEmergency('911'); // Can be customized per region
}
