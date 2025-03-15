import 'package:flutter/material.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for the inbox messages
    final messages = [
      {'title': 'You received a \$1.00 tip!', 'date': 'Yesterday'},
      {'title': 'You received a \$1.00 tip!', 'date': '3/4/24'},
      {'title': 'You received a \$3.00 tip!', 'date': '3/4/24'},
      {'title': 'You could earn more 😜', 'date': '3/4/24'},
      {'title': 'You received a \$1.00 tip!', 'date': '3/4/24'},
      {'title': 'Get up to \$1,000 off of a new Tesla ⚡', 'date': '3/3/24'},
      {
        'title': 'Save up to \$2,000 on a pre-owned Chevy Bolt',
        'date': '3/1/24',
      },
      {
        'title': 'Save up to \$2,000 on a pre-owned Chevy Bolt',
        'date': '3/1/24',
      },
      {'title': 'Upgrade your ride & boost your earnings', 'date': '3/1/24'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inbox"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Text(messages[index]['title']!),
            subtitle: Text(messages[index]['date']!),
            trailing: const Icon(
              Icons.circle,
              size: 10,
              color: Colors.blue,
            ), // Just like the blue dot in the screenshot
            onTap: () {
              // You can add any action when an item is tapped (e.g., navigate to message details)
            },
          );
        },
      ),
    );
  }
}
