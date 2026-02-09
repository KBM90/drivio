import 'package:drivio_app/common/models/notification_model.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  NotificationProvider() {
    _subscribeToNotifications();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final userId = await AuthService.getInternalUserId();
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false) // Only fetch unread
          .order('created_at', ascending: false)
          .limit(50);

      _notifications =
          (response as List)
              .map((data) => NotificationModel.fromJson(data))
              .toList();

      _calculateUnreadCount();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // Optimistic update
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        // Create a new instance with isRead = true (assuming NotificationModel is immutable or we replace it)
        // Since NotificationModel fields are final, we need to replace the item.
        // But wait, NotificationModel doesn't have copyWith. Let's just assume we can't modify it easily without copyWith.
        // For now, let's just update the list by re-fetching or manually constructing if needed.
        // Or better, let's add copyWith to NotificationModel later if needed.
        // For now, let's just update the local state if we can, or just rely on fetch.
        // Actually, let's just update the database and then update the local list manually to avoid a fetch.

        // We can't easily modify the final field. Let's just update the DB and rely on the subscription or re-fetch?
        // Subscription might not trigger on UPDATE if we only listen to INSERT.
        // Let's update the subscription to listen to UPDATEs too.

        await _supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('id', notificationId);

        // Manually update local state for immediate UI feedback
        // We need to create a new object or cast to dynamic if we want to cheat, but better to be type safe.
        // Let's just re-fetch for now or update the count.
        // Actually, let's just update the count and the item in the list.
        // Since we don't have copyWith, let's just assume we can't update the object in place.
        // Let's just decrement unread count if it was unread.
        if (!_notifications[index].isRead) {
          _unreadCount--;
          _notifications.removeAt(
            index,
          ); // Remove from list since we only show unread
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    final userId = await AuthService.getInternalUserId();
    if (userId == null) return;

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      // Optimistic update
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  void _calculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  void _subscribeToNotifications() async {
    final userId = await AuthService.getInternalUserId();
    if (userId == null) return;

    _supabase
        .channel('public:notifications:provider')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.insert) {
              final newNotification = NotificationModel.fromJson(
                payload.newRecord,
              );
              _notifications.insert(0, newNotification);
              _unreadCount++;
              notifyListeners();
            } else if (payload.eventType == PostgresChangeEvent.update) {
              // Handle update (e.g. read status changed from another device)
              final updatedNotification = NotificationModel.fromJson(
                payload.newRecord,
              );
              if (updatedNotification.isRead) {
                _notifications.removeWhere(
                  (n) => n.id == updatedNotification.id,
                );
                _calculateUnreadCount();
                notifyListeners();
              } else {
                final index = _notifications.indexWhere(
                  (n) => n.id == updatedNotification.id,
                );
                if (index != -1) {
                  _notifications[index] = updatedNotification;
                  _calculateUnreadCount();
                  notifyListeners();
                }
              }
            }
          },
        )
        .subscribe();
  }
}
