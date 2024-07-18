import 'package:flutter/material.dart';
import 'package:test_ably/ably_page.dart';
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
      home: AblyPage(
        messagePage: MessagePage(messages: messages),
        onMessageReceived: _addMessage,
      ),
    );
  }
}
