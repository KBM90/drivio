class Message {
  final String id;
  final String chatId;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? senderName;
  final String? senderRole; // 'passenger' or 'driver'

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.senderName,
    this.senderRole,
  });

  // From Supabase
  factory Message.fromSupabase(Map<String, dynamic> data) {
    return Message(
      id: data['id']?.toString() ?? '',
      chatId: data['chat_id'] as String,
      senderId: data['sender_id'] as int,
      receiverId: data['receiver_id'] as int,
      message: data['message'] as String,
      timestamp: DateTime.parse(data['timestamp'] as String).toLocal(),
      isRead: data['is_read'] as bool? ?? false,
      senderName: data['sender_name'] as String?,
      senderRole: data['sender_role'] as String?,
    );
  }

  // To Supabase
  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      if (senderName != null) 'sender_name': senderName,
      if (senderRole != null) 'sender_role': senderRole,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    int? senderId,
    int? receiverId,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? senderName,
    String? senderRole,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
    );
  }
}
