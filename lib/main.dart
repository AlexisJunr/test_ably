import 'package:flutter/material.dart';
import 'package:test_ably/ably_chatroom_bridge.dart';
import 'package:test_ably/message_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final List<String> messages = [];

  void _addMessage(String message) {
    setState(() {
      messages.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Test avec WebSocket'),
        ),
        body: Stack(
          children: [
            AblyChatroomBridge(
              onMessageReceived: _addMessage,
              width: 0,
              height: 0,
              apiKey: 'DrxRqA.f6AqdA:J6_FmVgT03gro-I-s5W5_n71XVK7fi7bPW3vSChIijo',
              clientId: 'user-id',
              channelName: '1',
            ),
            Expanded(
              child: MessagePage(messages: messages),
            ),
          ],
        ),
      ),
    );
  }
}