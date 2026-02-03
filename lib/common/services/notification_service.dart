import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.messageId}');
  print('📦 Title: ${message.notification?.title}');
  print('📦 Body: ${message.notification?.body}');

  // Show local notification
  await NotificationService._showLocalNotificationFromFCM(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
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

    // Initialize Firebase Cloud Messaging
    await _initializeFirebaseMessaging();

    // Start listening for Supabase notifications (for in-app updates)
    await _listenForNotifications();
  }

  static Future<void> _initializeFirebaseMessaging() async {
    print('🔥 Initializing Firebase Cloud Messaging...');

    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('✅ FCM Permission status: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('🔑 FCM Token: $token');
      await _saveFCMTokenToSupabase(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed: $newToken');
      _saveFCMTokenToSupabase(newToken);
    });

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message received: ${message.messageId}');
      print('📦 Title: ${message.notification?.title}');
      print('📦 Body: ${message.notification?.body}');

      _showLocalNotificationFromFCM(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification opened app: ${message.messageId}');
      // Handle navigation based on message data
    });

    // Check if app was opened from a terminated state via notification
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('🔔 App opened from terminated state: ${initialMessage.messageId}');
      // Handle navigation based on message data
    }
  }

  static Future<void> _saveFCMTokenToSupabase(String token) async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) {
        print('❌ Cannot save FCM token: User not logged in');
        return;
      }

      // Upsert token (insert or update if exists)
      await _supabase.from('user_fcm_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id', // Specify the conflict column
      );

      print('✅ FCM token saved to Supabase for user $userId');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  static Future<void> _showLocalNotificationFromFCM(
    RemoteMessage message,
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
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  static Future<void> _listenForNotifications() async {
    final userId = await AuthService.getInternalUserId();
    if (userId == null) {
      print(
        '❌ User not logged in or internal ID not found, cannot listen for notifications',
      );
      return;
    }

    print('✅ Listening for Supabase notifications for user: $userId');

    // Using PostgresChanges for real-time inserts (for in-app notification list updates)
    try {
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
            callback: (payload) async {
              print('🔔 NEW NOTIFICATION IN DATABASE!');
              print('📦 Payload: ${payload.newRecord}');

              // Show local notification for the new database entry
              final newRecord = payload.newRecord;
              await _showLocalNotificationFromDatabase(
                title: newRecord['title'] as String? ?? 'New Notification',
                body: newRecord['body'] as String? ?? '',
                data: newRecord['data'] as Map<String, dynamic>?,
                notificationId:
                    newRecord['id'] as int? ??
                    DateTime.now().millisecondsSinceEpoch,
              );
            },
          )
          .subscribe();

      print('📡 Supabase channel subscribed successfully');
    } catch (e) {
      print('❌ Error setting up Supabase notification listener: $e');
    }
  }

  /// Show local notification from database record
  static Future<void> _showLocalNotificationFromDatabase({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    required int notificationId,
  }) async {
    try {
      // Load user preferences
      final soundEnabled =
          await SharedPreferencesHelper().getValue<bool>('soundEnabled') ??
          true;
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
        notificationId,
        title,
        body,
        notificationDetails,
        payload: data?.toString(),
      );

      print('✅ Local notification shown: $title');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  /// Send a notification to a specific user
  static Future<void> sendNotificationToUser({
    required int userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Notification sent to user $userId: $title');
    } catch (e) {
      print('❌ Error sending notification: $e');
      rethrow;
    }
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

    // Delete FCM token from Supabase
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId != null) {
        await _supabase.from('user_fcm_tokens').delete().eq('user_id', userId);
      }
    } catch (e) {
      print('Error deleting FCM token: $e');
    }

    // Delete FCM token from Firebase
    await _firebaseMessaging.deleteToken();

    _isInitialized = false;
  }

  /// Enable notifications (re-initialize if needed)
  static Future<void> enableNotifications() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
