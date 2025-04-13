// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:drivio_app/common/services/message_services.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  late DriverProvider driverProvider;

  @override
  void initState() {
    super.initState();
    driverProvider = Provider.of<DriverProvider>(context, listen: false);
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
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isDriver ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      message['message'],
                      style: const TextStyle(fontSize: 16),
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
