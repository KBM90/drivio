import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/earnings_data.dart';

class EarningsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current week earnings for a driver
  Future<EarningsData?> getCurrentWeekEarnings(int driverId) async {
    try {
      final response = await _supabase.rpc(
        'get_driver_current_week_earnings',
        params: {'p_driver_id': driverId},
      );

      if (response == null || (response is List && response.isEmpty)) {
        // Return empty earnings data if no data found
        final now = DateTime.now();
        final weekStart = _getWeekStart(now);
        final weekEnd = _getWeekEnd(weekStart);

        return EarningsData(
          totalBalance: 0.0,
          cashEarnings: 0.0,
          bankTransferEarnings: 0.0,
          otherEarnings: 0.0,
          totalTrips: 0,
          onlineHours: 0,
          onlineMinutes: 0,
          points: 0,
          nextPayoutDate: null,
          nextPayoutAmount: 0.0,
          periodStart: weekStart,
          periodEnd: weekEnd,
        );
      }

      // Handle response - it could be a single object or a list with one item
      final data = response is List ? response.first : response;

      // Add period dates
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekEnd = _getWeekEnd(weekStart);

      final earningsData = Map<String, dynamic>.from(data);
      earningsData['period_start'] = weekStart.toIso8601String();
      earningsData['period_end'] = weekEnd.toIso8601String();

      return EarningsData.fromJson(earningsData);
    } catch (e) {
      print('Error fetching current week earnings: $e');
      rethrow;
    }
  }

  /// Get earnings for a specific date range
  Future<EarningsData?> getEarningsForPeriod(
    int driverId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // First refresh the summary for this period
      await _supabase.rpc(
        'refresh_driver_earnings_summary',
        params: {
          'p_driver_id': driverId,
          'p_period_start': startDate.toIso8601String().split('T')[0],
          'p_period_end': endDate.toIso8601String().split('T')[0],
        },
      );

      // Then fetch the summary
      final response =
          await _supabase
              .from('driver_earnings_summary')
              .select()
              .eq('driver_id', driverId)
              .eq('period_start', startDate.toIso8601String().split('T')[0])
              .eq('period_end', endDate.toIso8601String().split('T')[0])
              .maybeSingle();

      if (response == null) {
        return EarningsData(
          totalBalance: 0.0,
          cashEarnings: 0.0,
          bankTransferEarnings: 0.0,
          otherEarnings: 0.0,
          totalTrips: 0,
          onlineHours: 0,
          onlineMinutes: 0,
          points: 0,
          nextPayoutDate: null,
          nextPayoutAmount: 0.0,
          periodStart: startDate,
          periodEnd: endDate,
        );
      }

      final earningsData = Map<String, dynamic>.from(response);
      earningsData['period_start'] = startDate.toIso8601String();
      earningsData['period_end'] = endDate.toIso8601String();

      return EarningsData.fromJson(earningsData);
    } catch (e) {
      print('Error fetching earnings for period: $e');
      rethrow;
    }
  }

  /// Get week start (Monday)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: weekday - 1));
  }

  /// Get week end (Sunday)
  DateTime _getWeekEnd(DateTime weekStart) {
    return weekStart.add(const Duration(days: 6));
  }

  /// Stream earnings updates in real-time
  Stream<EarningsData?> streamCurrentWeekEarnings(int driverId) async* {
    // Initial fetch
    yield await getCurrentWeekEarnings(driverId);

    // Create a stream controller to emit earnings updates
    final controller = StreamController<EarningsData?>();

    // Listen to changes in ride_payments and driver_online_sessions
    final channel = _supabase.channel('earnings_updates_$driverId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ride_payments',
          callback: (payload) async {
            // Refetch earnings when ride_payments changes
            final earnings = await getCurrentWeekEarnings(driverId);
            controller.add(earnings);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'driver_online_sessions',
          callback: (payload) async {
            // Refetch earnings when driver_online_sessions changes
            final earnings = await getCurrentWeekEarnings(driverId);
            controller.add(earnings);
          },
        )
        .subscribe();

    // Yield updates from the controller
    await for (final earnings in controller.stream) {
      yield earnings;
    }

    // Clean up when stream is cancelled
    await channel.unsubscribe();
    await controller.close();
  }
}
