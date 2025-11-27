import 'package:drivio_app/common/models/report.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  /// Submit a report for a user
  /// [reportedUserId] - The ID of the user being reported
  /// [reason] - The reason for the report (must match one from ReportReasons)
  /// [details] - Optional additional details about the report
  static Future<void> submitReport({
    required int reportedUserId,
    required String reason,
    String? details,
  }) async {
    try {
      // Get the current user's ID
      final currentUserId = await AuthService.getInternalUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('📝 Submitting report: $reason for user $reportedUserId');

      // Create the report object
      final report = Report(
        reportedBy: currentUserId,
        reportedUser: reportedUserId,
        reason: reason,
        details: details,
        status: 'pending',
      );

      // Ensure session is valid before making DB calls
      await AuthService.ensureValidSession();

      // Insert into Supabase
      await Supabase.instance.client
          .from('reports')
          .insert(report.toCreateJson());

      debugPrint('✅ Report submitted successfully');
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase error submitting report: ${e.message}');
      throw Exception('Failed to submit report: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error submitting report: $e');
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Get all reports made by the current user
  static Future<List<Report>> getMyReports() async {
    try {
      final currentUserId = await AuthService.getInternalUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Ensure session is valid before making DB calls
      await AuthService.ensureValidSession();

      final response = await Supabase.instance.client
          .from('reports')
          .select()
          .eq('reported_by', currentUserId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Report.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching reports: $e');
      return [];
    }
  }
}
