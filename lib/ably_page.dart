import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';

const apiKey = 'DrxRqA.f6AqdA:J6_FmVgT03gro-I-s5W5_n71XVK7fi7bPW3vSChIijo';
const clientId = 'DIpz4d94Ww';
const channelName = 'id-du-channel';

final webSocketUrl = Uri.parse('wss://realtime.ably.io:443/?key=$apiKey&clientId=$clientId');

class AblyPage extends StatefulWidget {
  final Function(String) onMessageReceived;
  final Widget messagePage;

  const AblyPage({super.key, required this.onMessageReceived, required this.messagePage});

  @override
  State<AblyPage> createState() => _AblyPageState();
}

class _AblyPageState extends State<AblyPage> {
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

  void _initWebSocket() async {
    try {
      print('Initialisation de WebSocket...');
      channel = WebSocketChannel.connect(webSocketUrl);
      print('WebSocket connecté !');
      await channel?.ready;
      _subscribeToEvent(channel: channel!);
      _subscribeToChannel(channelName);
      print('Abonnement aux événements du canal');
    } catch (error) {
      print('Erreur lors de l\'initialisation de WebSocket: $error');
      _showErrorSnackBar('Erreur de connexion à WebSocket');
    }
  }

  void _subscribeToChannel(String channelName) {
    if (channel != null) {
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
            if (decodedMessage['action'] == 15 && decodedMessage['channel'] == channelName) {
              var formattedMessage = const JsonEncoder.withIndent('  ').convert(decodedMessage['messages'][0]);
              widget.onMessageReceived(formattedMessage);
            }
          } catch (e) {
            print('Erreur de décodage du message: $e');
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
              child: widget.messagePage,
            ),
          ],
        ),
      ),
    );
  }
}