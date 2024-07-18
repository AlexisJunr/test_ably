import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget {
  final List<String> messages;

  const MessagePage({super.key, required this.messages});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  Widget build(BuildContext context) {
    return widget.messages.isEmpty
        ? const Center(child: Text('Aucun message à afficher'))
        : ListView.builder(
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(widget.messages[index]),
              );
            },
          );
  }
}
