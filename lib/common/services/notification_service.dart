import 'package:drivio_app/common/models/notification_model.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final SupabaseClient _supabase = Supabase.instance.client;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notification tapped with payload: ${response.payload}');
        // Handle notification tap here
      },
    );

    // Create notification channel for Android (required for Android 8.0+)
    // Create notification channel for Android (required for Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'general_notifications', // id
      'General Notifications', // name
      description: 'General notifications for the app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Request permissions for Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Start listening for Supabase notifications
    await _listenForNotifications();
  }

  static Future<void> _listenForNotifications() async {
    final userId = await AuthService.getInternalUserId();
    if (userId == null) {
      print(
        '❌ User not logged in or internal ID not found, cannot listen for notifications',
      );
      return;
    }

    print('✅ Listening for notifications for user: $userId');

    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .listen((List<Map<String, dynamic>> data) {
          // Stream listener can be used for other purposes if needed
          // Currently using onPostgresChanges for real-time notifications
        });

    // Using PostgresChanges for real-time inserts is more appropriate for "push-like" behavior
    try {
      final channel =
          _supabase
              .channel('public:notifications')
              .onPostgresChanges(
                event: PostgresChangeEvent.insert,
                schema: 'public',
                table: 'notifications',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'user_id',
                  value: userId,
                ),
                callback: (payload) {
                  print('🔔 NEW NOTIFICATION RECEIVED!');
                  print('📦 Payload: ${payload.newRecord}');

                  try {
                    final notification = NotificationModel.fromJson(
                      payload.newRecord,
                    );
                    print('✅ Notification parsed successfully');
                    print('📝 Title: ${notification.title}');
                    print('📝 Body: ${notification.body}');

                    _showLocalNotification(notification);
                    print('✅ Local notification triggered');
                  } catch (e) {
                    print('❌ Error parsing notification: $e');
                  }
                },
              )
              .subscribe();

      print('📡 Channel subscribed successfully');

      // Check connection state after a delay
      Future.delayed(Duration(seconds: 2), () {
        print('🔌 Connection state: ${channel.socket?.connectionState}');
      });
    } catch (e) {
      print('❌ Error setting up notification listener: $e');
    }
  }

  static Future<void> _showLocalNotification(
    NotificationModel notification,
  ) async {
    // Load user preferences
    final soundEnabled =
        await SharedPreferencesHelper().getValue<bool>('soundEnabled') ?? true;
    final vibrationEnabled =
        await SharedPreferencesHelper().getValue<bool>('vibrationEnabled') ??
        true;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'general_notifications',
          'General Notifications',
          channelDescription: 'General notifications for the app',
          importance: Importance.max,
          priority: Priority.high,
          playSound: soundEnabled,
          enableVibration: vibrationEnabled,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: notification.data.toString(),
    );
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Update notification settings (sound and vibration)
  static Future<void> updateNotificationSettings({
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    // Recreate notification channel with updated settings
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'general_notifications',
      'General Notifications',
      description: 'General notifications for the app',
      importance: Importance.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Disable all notifications
  static Future<void> disableNotifications() async {
    // Cancel all active notifications
    await _localNotifications.cancelAll();

    // Unsubscribe from all Supabase channels
    await _supabase.removeAllChannels();

    _isInitialized = false;
  }

  /// Enable notifications (re-initialize if needed)
  static Future<void> enableNotifications() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
