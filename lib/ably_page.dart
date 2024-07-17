import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';

const apiKey = 'DrxRqA.f6AqdA:J6_FmVgT03gro-I-s5W5_n71XVK7fi7bPW3vSChIijo';
const clientId = 'DIpz4d94Ww';

final webSocketUrl = Uri.parse('wss://realtime.ably.io:443/?key=$apiKey&clientId=$clientId');

class AblyPage extends StatefulWidget {
  const AblyPage({super.key});

  @override
  State<AblyPage> createState() => _AblyPageState();
}

class _AblyPageState extends State<AblyPage> {
  List<String> displayedMessages = [];
  WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }

  @override
  void dispose() {
    _disposeWebSocket();
    super.dispose();
  }

  void _initWebSocket() {
    try {
      print('Initialisation de WebSocket...');
      channel = WebSocketChannel.connect(webSocketUrl);
      print('WebSocket connecté !');
      _subscribeToEvent(channel: channel!);
      _subscribeToChannel('id-du-channel');
      print('Abonnement aux événements du canal');
    } catch (error) {
      print('Erreur lors de l\'initialisation de WebSocket: $error');
      _showErrorSnackBar('Erreur de connexion à WebSocket');
    }
  }

  void _subscribeToChannel(String channelName) {
    if (channel != null) {
      var subscribeMessage = json.encode({
        "action": "subscribe",
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
          setState(() {
            try {
              var decodedMessage = json.decode(message);
              print('Message décodé: $decodedMessage');
              if (decodedMessage['action'] == 'message' && decodedMessage['channel'] == 'id-du-channel') {
                var formattedMessage = const JsonEncoder.withIndent('  ').convert(decodedMessage['data']);
                displayedMessages.add(formattedMessage);
              }
            } catch (e) {
              print('Erreur de décodage du message: $e');
              displayedMessages.add(message.toString());
            }
          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test avec WebSocket'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Écoute des messages...'),
            Expanded(
              child: ListView.builder(
                itemCount: displayedMessages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(displayedMessages[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
