import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsServices {
  Future<Map<String, dynamic>> createNotification({
    required userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .insert({
            'user_id': userId,
            'type': type,
            'title': title,
            'message': message,
            'data': data,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return {
        'success': true,
        'message': 'Notification created successfully',
        'notification': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception occurred while creating notification',
        'error': e.toString(),
      };
    }
  }
}
