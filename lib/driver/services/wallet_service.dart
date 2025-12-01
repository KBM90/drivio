import 'package:drivio_app/common/models/wallet.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/driver/models/driver_payout.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get wallet balance for a user
  Future<Wallet?> getWalletBalance(int userId) async {
    try {
      await AuthService.ensureValidSession();

      final response =
          await _supabase
              .from('wallets')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ No wallet found for user $userId');
        return null;
      }

      return Wallet.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching wallet balance: $e');
      rethrow;
    }
  }

  /// Get payout history for a user
  Future<List<DriverPayout>> getPayoutHistory(int userId) async {
    try {
      await AuthService.ensureValidSession();

      final response = await _supabase
          .from('driver_payouts')
          .select()
          .eq('driver_id', userId)
          .order('payout_date', ascending: false);

      if (response.isEmpty) {
        debugPrint('⚠️ No payout history found for user $userId');
        return [];
      }

      return (response as List)
          .map((json) => DriverPayout.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching payout history: $e');
      rethrow;
    }
  }
}
