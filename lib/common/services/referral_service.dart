import 'dart:math';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReferralService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate a unique referral code for the current user
  static Future<String> generateReferralCode() async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) throw Exception('User not authenticated');

      // Check if user already has a referral code
      final existing =
          await _supabase
              .from('referrals')
              .select('referral_code')
              .eq('referrer_id', userId)
              .maybeSingle();

      if (existing != null && existing['referral_code'] != null) {
        return existing['referral_code'] as String;
      }

      // Generate new unique code
      String code;
      bool isUnique = false;
      int attempts = 0;

      do {
        code = _generateRandomCode();
        final check =
            await _supabase
                .from('referrals')
                .select('id')
                .eq('referral_code', code)
                .maybeSingle();

        isUnique = check == null;
        attempts++;
      } while (!isUnique && attempts < 10);

      if (!isUnique) {
        throw Exception('Failed to generate unique referral code');
      }

      // Create referral entry
      await _supabase.from('referrals').insert({
        'referrer_id': userId,
        'referral_code': code,
        'status': 'active',
        'expires_at':
            DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      });

      return code;
    } catch (e) {
      debugPrint('❌ Error generating referral code: $e');
      throw Exception('Failed to generate referral code: $e');
    }
  }

  /// Get referral statistics for the current user
  static Future<Map<String, dynamic>> getReferralStats() async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) throw Exception('User not authenticated');

      // Get total referrals
      final referrals = await _supabase
          .from('referrals')
          .select()
          .eq('referrer_id', userId);

      // Get total rewards
      final rewards = await _supabase
          .from('referral_rewards')
          .select('amount, points, status')
          .eq('user_id', userId);

      double totalEarnings = 0;
      int totalPoints = 0;
      double pendingEarnings = 0;

      for (final reward in rewards) {
        final amount = (reward['amount'] as num?)?.toDouble() ?? 0;
        final points = (reward['points'] as int?) ?? 0;
        final status = reward['status'] as String?;

        totalPoints += points;

        if (status == 'paid') {
          totalEarnings += amount;
        } else if (status == 'pending' || status == 'approved') {
          pendingEarnings += amount;
        }
      }

      final activeReferrals =
          referrals.where((r) => r['status'] == 'active').length;
      final completedReferrals =
          referrals.where((r) => r['status'] == 'completed').length;

      return {
        'total_referrals': referrals.length,
        'active_referrals': activeReferrals,
        'completed_referrals': completedReferrals,
        'total_earnings': totalEarnings,
        'pending_earnings': pendingEarnings,
        'total_points': totalPoints,
      };
    } catch (e) {
      debugPrint('❌ Error getting referral stats: $e');
      return {
        'total_referrals': 0,
        'active_referrals': 0,
        'completed_referrals': 0,
        'total_earnings': 0.0,
        'pending_earnings': 0.0,
        'total_points': 0,
      };
    }
  }

  /// Get referral history for the current user
  static Future<List<Map<String, dynamic>>> getReferralHistory() async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) return [];

      final referrals = await _supabase
          .from('referrals')
          .select('*, referred_user:users!referred_user_id(name, email)')
          .eq('referrer_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(referrals);
    } catch (e) {
      debugPrint('❌ Error getting referral history: $e');
      return [];
    }
  }

  /// Apply a referral code during signup
  static Future<bool> applyReferralCode(String code, int newUserId) async {
    try {
      // Find the referral by code
      final referral =
          await _supabase
              .from('referrals')
              .select('id, referrer_id, status')
              .eq('referral_code', code)
              .eq('status', 'active')
              .maybeSingle();

      if (referral == null) {
        debugPrint('⚠️ Invalid or inactive referral code');
        return false;
      }

      // Update referral with new user
      await _supabase
          .from('referrals')
          .update({
            'referred_user_id': newUserId,
            'signup_completed': true,
            'signup_completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', referral['id']);

      // Create signup reward
      await _supabase.from('referral_rewards').insert({
        'referral_id': referral['id'],
        'user_id': referral['referrer_id'],
        'reward_type': 'points',
        'amount': 0,
        'points': 50, // 50 points for signup
        'status': 'approved',
        'milestone': 'signup',
        'description': 'Friend signed up',
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error applying referral code: $e');
      return false;
    }
  }

  /// Check and award rewards based on ride milestones
  static Future<void> checkRewardEligibility(int userId) async {
    try {
      // Get all referrals where this user is the referred user
      final referrals = await _supabase
          .from('referrals')
          .select('id, referrer_id, rides_completed')
          .eq('referred_user_id', userId)
          .eq('status', 'active');

      for (final referral in referrals) {
        final referralId = referral['id'] as int;
        final referrerId = referral['referrer_id'] as int;
        final ridesCompleted = (referral['rides_completed'] as int?) ?? 0;

        // Check milestones and award rewards
        final milestones = [
          {'rides': 1, 'points': 100, 'amount': 5.0, 'name': 'first_ride'},
          {'rides': 5, 'points': 200, 'amount': 10.0, 'name': '5_rides'},
          {'rides': 10, 'points': 300, 'amount': 15.0, 'name': '10_rides'},
          {'rides': 20, 'points': 500, 'amount': 25.0, 'name': '20_rides'},
        ];

        for (final milestone in milestones) {
          final requiredRides = milestone['rides'] as int;
          if (ridesCompleted >= requiredRides) {
            // Check if reward already exists
            final existing =
                await _supabase
                    .from('referral_rewards')
                    .select('id')
                    .eq('referral_id', referralId)
                    .eq('milestone', milestone['name'] as String)
                    .maybeSingle();

            if (existing == null) {
              // Create new reward
              await _supabase.from('referral_rewards').insert({
                'referral_id': referralId,
                'user_id': referrerId,
                'reward_type': 'cash',
                'amount': milestone['amount'],
                'points': milestone['points'],
                'status': 'approved',
                'milestone': milestone['name'],
                'description': 'Friend completed ${milestone['rides']} rides',
              });
            }
          }
        }

        // Mark as completed if 20 rides reached
        if (ridesCompleted >= 20) {
          await _supabase
              .from('referrals')
              .update({
                'status': 'completed',
                'completed_at': DateTime.now().toIso8601String(),
              })
              .eq('id', referralId);
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking reward eligibility: $e');
    }
  }

  /// Increment ride count for a user's referrals
  static Future<void> incrementRideCount(int userId) async {
    try {
      await _supabase.rpc(
        'increment_referral_rides',
        params: {'p_user_id': userId},
      );

      // Check for new rewards
      await checkRewardEligibility(userId);
    } catch (e) {
      debugPrint('❌ Error incrementing ride count: $e');
    }
  }

  /// Generate random alphanumeric code
  static String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude similar chars
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
