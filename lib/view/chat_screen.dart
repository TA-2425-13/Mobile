
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Levely Chat'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Chat Sessions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Session 1'),
              onTap: () {
                // TODO: Navigate to chat session 1
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Session 2'),
              onTap: () {
                // TODO: Navigate to chat session 2
                Navigator.pop(context);
              },
            ),
            // Add more chat sessions here
          ],
        ),
      ),
      body: const Center(
        child: Text('Start a new chat!'),
      ),
    );
  }
}
