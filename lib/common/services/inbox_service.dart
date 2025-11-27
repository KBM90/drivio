import 'package:drivio_app/common/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InboxService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch system notifications (category = 'system' or null)
  static Future<List<Map<String, dynamic>>> getSystemNotifications() async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) return [];

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .or('data->>category.eq.system,data->>category.is.null')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // debugPrint('Error fetching system notifications: $e');
      return [];
    }
  }

  /// Fetch reward notifications (category = 'reward')
  static Future<List<Map<String, dynamic>>> getRewardNotifications() async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) return [];

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('data->>category', 'reward')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // debugPrint('Error fetching reward notifications: $e');
      return [];
    }
  }

  /// Fetch active chats for the current user (driver)
  /// This joins with the 'messages' table to get the last message details if needed,
  /// but the 'chats' table already has 'last_message' and 'last_message_time'.
  /// We also need to fetch the OTHER participant's details (the passenger).
  static Future<List<Map<String, dynamic>>> getPassengerChats() async {
    try {
      final internalUserId = await AuthService.getInternalUserId();
      if (internalUserId == null) return [];

      // Fetch chats where the user is a participant
      final response = await _supabase
          .from('chats')
          .select()
          .contains('participants', [internalUserId])
          .order('updated_at', ascending: false);

      final List<Map<String, dynamic>> chatsWithDetails = [];

      for (final chat in response) {
        final participants = List<int>.from(chat['participants']);
        final otherUserId = participants.firstWhere(
          (id) => id != internalUserId,
          orElse: () => -1,
        );

        if (otherUserId != -1) {
          // Fetch other user's details (Passenger)
          // We check the 'users' table first, then 'passengers' for profile image if needed
          final userResponse =
              await _supabase
                  .from('users')
                  .select('name, profile_image, role')
                  .eq('id', otherUserId)
                  .single();

          // If the other user is a passenger, we might want to get more details from 'passengers' table
          // but 'users' table should have the basic info.

          chatsWithDetails.add({...chat, 'other_user': userResponse});
        }
      }

      return chatsWithDetails;
    } catch (e) {
      // debugPrint('Error fetching passenger chats: $e');
      return [];
    }
  }
}
