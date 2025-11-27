import 'package:drivio_app/common/services/inbox_service.dart';
import 'package:drivio_app/common/screens/chat_screen.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/common/helpers/date_time_helper.dart';
import 'package:flutter/material.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRideRequestNotification(
    BuildContext context,
    int rideRequestId,
  ) async {
    // Navigate back to the driver map view
    // The map view should be the previous screen in the navigation stack
    Navigator.pop(context);

    // Show a brief message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading ride request #$rideRequestId...'),
        duration: const Duration(seconds: 1),
      ),
    );

    // TODO: The driver_map_view should listen for this and focus on the ride request
    // For now, the driver will need to manually tap the marker on the map
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inbox"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "System"),
            Tab(text: "Passengers"),
            Tab(text: "Rewards"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // System Tab
          _buildNotificationList(InboxService.getSystemNotifications()),

          // Passengers Tab
          _buildChatList(),

          // Rewards Tab
          _buildNotificationList(InboxService.getRewardNotifications()),
        ],
      ),
    );
  }

  Widget _buildNotificationList(Future<List<Map<String, dynamic>>> future) {
    // Use Builder to capture the correct BuildContext that has access to providers
    return Builder(
      builder: (builderContext) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            debugPrint(
              '🔍 Notification list state: ${snapshot.connectionState}',
            );
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              debugPrint('❌ Error in notification list: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              debugPrint(
                '⚠️ No notifications data: hasData=${snapshot.hasData}, length=${snapshot.data?.length}',
              );
              return const Center(child: Text('No messages'));
            }

            final notifications = snapshot.data!;
            debugPrint('✅ Displaying ${notifications.length} notifications');
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['is_read'] as bool? ?? false;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  title: Text(
                    notification['title'] ?? 'No Title',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notification['body'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateTimeHelper.formatDate(notification['created_at']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing:
                      !isRead
                          ? const Icon(
                            Icons.circle,
                            size: 10,
                            color: Colors.blue,
                          )
                          : null,
                  onTap: () async {
                    final data = notification['data'];
                    if (data != null &&
                        data is Map &&
                        data['ride_request_id'] != null) {
                      final rideRequestId = data['ride_request_id'] as int;
                      // Use builderContext which has access to providers
                      _handleRideRequestNotification(
                        builderContext,
                        rideRequestId,
                      );
                    } else {
                      // TODO: Mark as read or show generic details
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: InboxService.getPassengerChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No messages'));
        }

        final chats = snapshot.data!;
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final otherUser = chat['other_user'] as Map<String, dynamic>;
            final lastMessage = chat['last_message'] as String? ?? '';
            final lastMessageTime = chat['last_message_time'] as String?;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    otherUser['profile_image'] != null
                        ? NetworkImage(otherUser['profile_image'])
                        : null,
                child:
                    otherUser['profile_image'] == null
                        ? const Icon(Icons.person)
                        : null,
              ),
              title: Text(
                otherUser['name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                DateTimeHelper.formatDate(lastMessageTime),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () async {
                final currentUserId = await AuthService.getInternalUserId();
                final participants = List<dynamic>.from(chat['participants']);
                final otherUserId = participants.firstWhere(
                  (id) => id != currentUserId,
                );

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatScreen(
                            otherUserId: otherUserId,
                            currentUserId: currentUserId!,
                            otherUserName: otherUser['name'] ?? 'Passenger',
                            currentUserName: 'Driver',
                            currentUserRole: 'driver',
                          ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
