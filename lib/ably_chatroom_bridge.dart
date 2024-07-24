import 'package:flutter/material.dart';
import 'package:test_ably/message_model.dart';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class AblyChatroomBridge extends StatefulWidget {
  final double width;
  final double height;

  final String apiKey;
  final String clientId;
  final String channelName;

  final Function(ChatroomMessageStruct) onMessageReceived;
  final Function()? onReady;

  const AblyChatroomBridge({
    super.key,
    required this.width,
    required this.height,
    required this.apiKey,
    required this.clientId,
    required this.channelName,
    required this.onMessageReceived,
    this.onReady,
  });

  @override
  State<AblyChatroomBridge> createState() => _AblyChatroomBridgeState();
}

class _AblyChatroomBridgeState extends State<AblyChatroomBridge> {
  WebSocketChannel? channel;
  Uri? webSocketUrl;
  bool isWebSocketReady = false;

  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isWebSocketReady) {
      _subscribeToChannel(widget.channelName);
    }
  }

  @override
  void didUpdateWidget(AblyChatroomBridge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelName != widget.channelName) {
      if (channel != null) {
        _disposeWebSocket();
      }
      _initWebSocket();
    }
  }

  @override
  void dispose() {
    _disposeWebSocket();
    super.dispose();
  }

  void _initWebSocket() async {
    webSocketUrl = Uri.parse('wss://realtime.ably.io:443/?key=${widget.apiKey}&clientId=${widget.clientId}');
    try {
      print('Initialisation de WebSocket...');
      channel = WebSocketChannel.connect(webSocketUrl!);
      print('WebSocket connecté !');
      await channel?.ready;
      isWebSocketReady = true;
      _subscribeToEvent(channel: channel!);
      if (widget.onReady != null) {
        widget.onReady!();
      }
      _subscribeToChannel(widget.channelName);
    } catch (error) {
      print('Erreur lors de l\'initialisation de WebSocket: $error');
      _showErrorSnackBar('Erreur de connexion à WebSocket');
    }
  }

  void _subscribeToChannel(String channelName) async {
    if (channel != null && isWebSocketReady) {
      await Future.delayed(const Duration(milliseconds: 500));
      var subscribeMessage = json.encode({
        "action": 10,
        "channel": channelName
      });
      channel!.sink.add(subscribeMessage);
      print('Connecté au canal: $channelName');
      _showSuccessSnackBar('Connecté au canal: $channelName');
    }
  }

  void _subscribeToEvent({required WebSocketChannel channel}) {
    channel.stream.listen(
      (message) {
        print('Message brut reçu: $message');
        if (mounted) {
          try {
            var decodedMessage = json.decode(message);
            print('Message décodé: $decodedMessage');

            switch (decodedMessage['action']) {
              case 0:
                print('Heartbeat !');
                break;
              case 15:
                if (decodedMessage['channel'] == widget.channelName) {
                  try {
                    var formattedMessage = json.decode(decodedMessage['messages'][0]['data']);
                    final chatroomMessage = _convertToChatroomMessage(formattedMessage);
                    widget.onMessageReceived(chatroomMessage);
                    print('Format ok');
                    setState(() {
                      messages.add(formattedMessage.toString());
                    });
                  } catch (error) {
                    print('Erreur de décodage du message: $error');
                  }
                }

                break;
              default:
                print('Action non reconnue: ${decodedMessage['action']}');
            }
          } catch (error) {
            print('Erreur de décodage du message: $error');
          }
        }
      },
      onError: (error) {
        print('Erreur de WebSocket: $error');
        _showErrorSnackBar('Erreur de WebSocket');
      },
      onDone: () {
        print('WebSocket fermé.');
        if (channel.closeCode != null) {
          print('Code de fermeture: ${channel.closeCode}');
        }
      },
    );
  }

  ChatroomMessageStruct _convertToChatroomMessage(Map<String, dynamic> formattedMessage) {
    final int userId = formattedMessage['user_id'];
    final String message = formattedMessage['message'];
    final int createdAt = formattedMessage['created_at'];
    final int id = formattedMessage['id'];
    final int chatroomId = formattedMessage['chatroom_id'];
    return ChatroomMessageStruct(
      id: id,
      userId: userId,
      message: message,
      createdAt: createdAt,
      chatroomId: chatroomId,
    );
  }

  void _disposeWebSocket() {
    try {
      if (channel != null) {
        channel!.sink.close(1000);
        print('WebSocket fermé proprement.');
      }
    } catch (error) {
      print('Erreur lors de la fermeture du WebSocket: $error');
    } finally {
      channel = null;
      isWebSocketReady = false;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              messages[index],
              style: const TextStyle(fontSize: 10),
            ),
          );
        },
      ),
    );
  }
}
