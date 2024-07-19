import 'package:flutter/material.dart';
import 'package:test_ably/message_model.dart';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';

class AblyChatroomBridge extends StatefulWidget {
  final double width;
  final double height;

  final String apiKey;
  final String clientId;
  final String channelName;

  final Function(ChatroomMessageStruct) onMessageReceived;

  const AblyChatroomBridge({
    super.key,
    required this.width,
    required this.height,
    required this.apiKey,
    required this.clientId,
    required this.channelName,
    required this.onMessageReceived,
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
      _subscribeToChannel(widget.channelName);
      _subscribeToEvent(channel: channel!);
      print('Abonnement aux événements du canal');
      _showSuccessSnackBar('Connecté au canal: ${widget.channelName}');
    } catch (error) {
      print('Erreur lors de l\'initialisation de WebSocket: $error');
      _showErrorSnackBar('Erreur de connexion à WebSocket');
    }
  }

  void _subscribeToChannel(String channelName) {
    if (channel != null && isWebSocketReady) {
      var subscribeMessage = json.encode({
        "action": 10,
        "channel": channelName
      });
      channel!.sink.add(subscribeMessage);
      print('Abonné au canal: $channelName');
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
                    widget.onMessageReceived(ChatroomMessageStruct.fromMap(formattedMessage));
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

  void _disposeWebSocket() {
    try {
      channel?.sink.close(status.goingAway);
    } catch (error) {
      print('Erreur lors de la fermeture du WebSocket: $error');
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