import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpportunitiesService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get events in the driver's city
  static Future<List<Map<String, dynamic>>> getLocalEvents(String city) async {
    try {
      final now = DateTime.now();

      final events = await _supabase
          .from('events')
          .select()
          .eq('city', city)
          .eq('status', 'upcoming')
          .gte('start_time', now.toIso8601String())
          .order('start_time', ascending: true)
          .limit(20);

      return List<Map<String, dynamic>>.from(events);
    } catch (e) {
      debugPrint('❌ Error fetching local events: $e');
      return [];
    }
  }

  /// Get all upcoming events (no city filter)
  static Future<List<Map<String, dynamic>>> getAllUpcomingEvents() async {
    try {
      final now = DateTime.now();

      final events = await _supabase
          .from('events')
          .select()
          .eq('status', 'upcoming')
          .gte('start_time', now.toIso8601String())
          .order('start_time', ascending: true)
          .limit(50);

      return List<Map<String, dynamic>>.from(events);
    } catch (e) {
      debugPrint('❌ Error fetching all events: $e');
      return [];
    }
  }

  /// Get active campaigns available to join
  static Future<List<Map<String, dynamic>>> getActiveCampaigns({
    String? city,
  }) async {
    try {
      // First update campaign statuses
      await _supabase.rpc('update_campaign_status');

      var query = _supabase.from('campaigns').select().eq('status', 'active');

      // Filter by city if provided
      if (city != null) {
        query = query.or('city_restriction.is.null,city_restriction.eq.$city');
      }

      final campaigns = await query
          .order('priority', ascending: false)
          .order('start_date', ascending: true);
      return List<Map<String, dynamic>>.from(campaigns);
    } catch (e) {
      debugPrint('❌ Error fetching active campaigns: $e');
      return [];
    }
  }

  /// Get campaigns the driver has joined
  static Future<List<Map<String, dynamic>>> getMyCampaigns() async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) return [];

      // Get driver ID
      final driver =
          await _supabase
              .from('drivers')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();

      if (driver == null) return [];
      final driverId = driver['id'] as int;

      // Get participations with campaign details
      final participations = await _supabase
          .from('campaign_participants')
          .select('*, campaign:campaigns(*)')
          .eq('driver_id', driverId)
          .inFilter('status', ['active', 'completed'])
          .order('joined_at', ascending: false);

      return List<Map<String, dynamic>>.from(participations);
    } catch (e) {
      debugPrint('❌ Error fetching my campaigns: $e');
      return [];
    }
  }

  /// Join a campaign
  static Future<bool> joinCampaign(int campaignId) async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) return false;

      // Get driver ID
      final driver =
          await _supabase
              .from('drivers')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();

      if (driver == null) return false;
      final driverId = driver['id'] as int;

      // Check if campaign is still accepting participants
      final campaign =
          await _supabase
              .from('campaigns')
              .select('max_participants, current_participants, status')
              .eq('id', campaignId)
              .maybeSingle();

      if (campaign == null || campaign['status'] != 'active') {
        debugPrint('⚠️ Campaign not available');
        return false;
      }

      final maxParticipants = campaign['max_participants'] as int?;
      final currentParticipants =
          (campaign['current_participants'] as int?) ?? 0;

      if (maxParticipants != null && currentParticipants >= maxParticipants) {
        debugPrint('⚠️ Campaign is full');
        return false;
      }

      // Check if already joined
      final existing =
          await _supabase
              .from('campaign_participants')
              .select('id')
              .eq('campaign_id', campaignId)
              .eq('driver_id', driverId)
              .maybeSingle();

      if (existing != null) {
        debugPrint('⚠️ Already joined this campaign');
        return false;
      }

      // Join campaign
      await _supabase.from('campaign_participants').insert({
        'campaign_id': campaignId,
        'driver_id': driverId,
        'status': 'active',
        'progress': {},
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error joining campaign: $e');
      return false;
    }
  }

  /// Get campaign progress for the current driver
  static Future<Map<String, dynamic>?> getCampaignProgress(
    int campaignId,
  ) async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) return null;

      // Get driver ID
      final driver =
          await _supabase
              .from('drivers')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();

      if (driver == null) return null;
      final driverId = driver['id'] as int;

      final participation =
          await _supabase
              .from('campaign_participants')
              .select('*, campaign:campaigns(*)')
              .eq('campaign_id', campaignId)
              .eq('driver_id', driverId)
              .maybeSingle();

      return participation;
    } catch (e) {
      debugPrint('❌ Error fetching campaign progress: $e');
      return null;
    }
  }

  /// Update campaign progress (called after ride completion)
  static Future<void> updateCampaignProgress(
    int driverId,
    Map<String, dynamic> rideData,
  ) async {
    try {
      // Get all active campaigns for this driver
      final participations = await _supabase
          .from('campaign_participants')
          .select('*, campaign:campaigns(*)')
          .eq('driver_id', driverId)
          .eq('status', 'active');

      for (final participation in participations) {
        final campaign = participation['campaign'] as Map<String, dynamic>;
        final campaignType = campaign['campaign_type'] as String;
        final goalCriteria = campaign['goal_criteria'] as Map<String, dynamic>;
        final progress = Map<String, dynamic>.from(
          participation['progress'] as Map? ?? {},
        );

        // Update progress based on campaign type
        switch (campaignType) {
          case 'ride_count':
            progress['rides_completed'] =
                (progress['rides_completed'] ?? 0) + 1;
            break;
          case 'earnings':
            final earnings = rideData['fare'] as num? ?? 0;
            progress['total_earnings'] =
                (progress['total_earnings'] ?? 0) + earnings;
            break;
          case 'hours':
            final duration = rideData['duration_minutes'] as num? ?? 0;
            progress['hours_worked'] =
                (progress['hours_worked'] ?? 0) + (duration / 60);
            break;
          case 'combo':
            progress['rides_completed'] =
                (progress['rides_completed'] ?? 0) + 1;
            final earnings = rideData['fare'] as num? ?? 0;
            progress['total_earnings'] =
                (progress['total_earnings'] ?? 0) + earnings;
            break;
        }

        // Calculate completion percentage
        double completionPercentage = 0;
        bool isCompleted = false;

        switch (campaignType) {
          case 'ride_count':
            final target = goalCriteria['rides'] as int;
            final completed = progress['rides_completed'] as int? ?? 0;
            completionPercentage = (completed / target * 100).clamp(0, 100);
            isCompleted = completed >= target;
            break;
          case 'earnings':
            final target = goalCriteria['earnings'] as num;
            final completed = progress['total_earnings'] as num? ?? 0;
            completionPercentage = (completed / target * 100).clamp(0, 100);
            isCompleted = completed >= target;
            break;
          case 'hours':
            final target = goalCriteria['hours'] as num;
            final completed = progress['hours_worked'] as num? ?? 0;
            completionPercentage = (completed / target * 100).clamp(0, 100);
            isCompleted = completed >= target;
            break;
        }

        // Update participation
        await _supabase
            .from('campaign_participants')
            .update({
              'progress': progress,
              'completion_percentage': completionPercentage,
              'is_completed': isCompleted,
              'completed_at':
                  isCompleted ? DateTime.now().toIso8601String() : null,
              'status': isCompleted ? 'completed' : 'active',
              'reward_earned': isCompleted,
              'reward_amount': isCompleted ? campaign['reward_amount'] : 0,
              'reward_points': isCompleted ? campaign['reward_points'] : 0,
            })
            .eq('id', participation['id']);
      }
    } catch (e) {
      debugPrint('❌ Error updating campaign progress: $e');
    }
  }

  /// Withdraw from a campaign
  static Future<bool> withdrawFromCampaign(int campaignId) async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) return false;

      // Get driver ID
      final driver =
          await _supabase
              .from('drivers')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();

      if (driver == null) return false;
      final driverId = driver['id'] as int;

      await _supabase
          .from('campaign_participants')
          .update({'status': 'withdrawn'})
          .eq('campaign_id', campaignId)
          .eq('driver_id', driverId);

      return true;
    } catch (e) {
      debugPrint('❌ Error withdrawing from campaign: $e');
      return false;
    }
  }
}
