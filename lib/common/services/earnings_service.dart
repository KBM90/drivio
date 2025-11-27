import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/earnings_data.dart';
import '../models/trip_detail.dart';

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
          totalEarnings: 0.0,
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
      final pStart = startDate.toIso8601String().split('T')[0];
      final pEnd = endDate.toIso8601String().split('T')[0];

      debugPrint(
        '🔄 Refreshing earnings for Driver $driverId: $pStart to $pEnd',
      );

      // First refresh the summary for this period
      await _supabase.rpc(
        'refresh_driver_earnings_summary',
        params: {
          'p_driver_id': driverId,
          'p_period_start': pStart,
          'p_period_end': pEnd,
        },
      );

      // Then fetch the summary
      final response =
          await _supabase
              .from('driver_earnings_summary')
              .select()
              .eq('driver_id', driverId)
              .eq('period_start', pStart)
              .eq('period_end', pEnd)
              .maybeSingle();

      debugPrint('📊 Earnings response: $response');

      if (response == null) {
        debugPrint('⚠️ No earnings summary found for period');
        return EarningsData(
          totalEarnings: 0.0,
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
      debugPrint('❌ Error fetching earnings for period: $e');
      rethrow;
    }
  }

  /// Get earnings for a single day
  Future<EarningsData?> getDailyEarnings(int driverId, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return getEarningsForPeriod(driverId, dayStart, dayEnd);
  }

  /// Get detailed trip information for a single day
  Future<List<TripDetail>> getDailyTripDetails(
    int driverId,
    DateTime date,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      debugPrint('🔄 Fetching trip details for Driver $driverId on $dateStr');

      final response = await _supabase
          .from('ride_requests')
          .select('''
            id,
            created_at,
            distance,
            price,
            status,
            ride_payments!inner(
              driver_earnings,
              commission_percentage,
              user_payment_method_id
            ),
            payment_methods!ride_requests_payment_method_id_fkey(
              name
            )
          ''')
          .eq('driver_id', driverId)
          .gte('created_at', '${dateStr}T00:00:00')
          .lte('created_at', '${dateStr}T23:59:59')
          .order('created_at', ascending: false);

      debugPrint('📊 Trip details response: $response');

      if (response == null || response.isEmpty) {
        debugPrint('⚠️ No trips found for this day');
        return [];
      }

      final trips = <TripDetail>[];
      for (final trip in response) {
        try {
          final payments = trip['ride_payments'] as List;
          if (payments.isEmpty) continue;

          final payment = payments[0] as Map<String, dynamic>;
          final paymentMethod =
              trip['payment_methods'] as Map<String, dynamic>?;

          final driverEarnings =
              (payment['driver_earnings'] as num?)?.toDouble() ?? 0.0;
          final commissionPct =
              (payment['commission_percentage'] as num?)?.toDouble() ?? 0.0;
          final price = (trip['price'] as num?)?.toDouble() ?? 0.0;
          final commissionAmount = price * (commissionPct / 100);

          trips.add(
            TripDetail.fromJson({
              'id': trip['id'],
              'created_at': trip['created_at'],
              'distance': trip['distance'],
              'price': price,
              'payment_method_name': paymentMethod?['name'] ?? 'Unknown',
              'commission_percentage': commissionPct,
              'commission_amount': commissionAmount,
              'driver_earnings': driverEarnings,
              'status': trip['status'],
            }),
          );
        } catch (e) {
          debugPrint('⚠️ Error parsing trip: $e');
          continue;
        }
      }

      debugPrint('✅ Found ${trips.length} trips');
      return trips;
    } catch (e) {
      debugPrint('❌ Error fetching trip details: $e');
      return [];
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
