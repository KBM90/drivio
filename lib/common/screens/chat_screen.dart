// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:drivio_app/common/helpers/date_time_helpers.dart';
import 'package:drivio_app/common/services/message_services.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final int passengerId;
  final int driverId; // ID of the passenger (receiver)

  const ChatScreen({
    super.key,
    required this.passengerId,
    required this.driverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  late MessageService _messageService;
  // Replace with the authenticated driver's ID
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Initialize MessageService
    _messageService = MessageService();

    // Fetch initial messages
    _fetchMessages();

    // Start polling for new messages every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Fetch messages from the API
  Future<void> _fetchMessages() async {
    final messages = await _messageService.fetchMessages(widget.passengerId);
    setState(() {
      _messages = messages;
    });
  }

  // Send a message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final success = await _messageService.sendMessage(
      widget.passengerId,
      _messageController.text,
    );
    if (success) {
      _messageController.clear();
      // Fetch messages immediately after sending to update the UI
      await _fetchMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Melody')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isDriver = message['sender_id'] == widget.driverId;

                return Align(
                  alignment:
                      isDriver ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ),
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width *
                          0.7, // Limit bubble width
                    ),
                    decoration: BoxDecoration(
                      color: isDriver ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.0).copyWith(
                        // Adjust border radius based on sender
                        topLeft:
                            isDriver
                                ? const Radius.circular(12.0)
                                : const Radius.circular(0),
                        topRight:
                            isDriver
                                ? const Radius.circular(0)
                                : const Radius.circular(12.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isDriver
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['message'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ), // Space between message and timestamp
                        Text(
                          formatMessageDate(message['sent_at']),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
