import 'package:flutter/material.dart';
import 'package:ably_flutter/ably_flutter.dart' as ably;

const apiKey = 'DrxRqA.f6AqdA:J6_FmVgT03gro-I-s5W5_n71XVK7fi7bPW3vSChIijo';
const clientId = 'DIpz4d94Ww';

class AblyPage extends StatefulWidget {
  const AblyPage({super.key});

  @override
  State<AblyPage> createState() => _AblyPageState();
}

class _AblyPageState extends State<AblyPage> {
  List<String> displayedMessages = [];
  ably.Realtime? realtimeInstance;
  ably.RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    _initAbly();
  }

  @override
  void dispose() {
    _disposeAbly();
    super.dispose();
  }

  Future<void> _initAbly() async {
    try {
      print('Initialisation de Ably...');
      realtimeInstance = await _createAblyRealtimeInstance(apiKey: apiKey, clientId: clientId);
      print('Instance Ably créée.');
      channel = await _createAblyChannelInstance(realtimeInstance: realtimeInstance!, channelName: 'id-du-channel');
      print('Canal Ably créé.');
      _subscribeToEvent(channel: channel!);
      print('Abonnement aux événements du canal.');
    } catch (e) {
      print('Erreur lors de l\'initialisation de Ably: $e');
      _showErrorSnackBar('Erreur de connexion à Ably');
    }
  }

  Future<ably.Realtime> _createAblyRealtimeInstance({
    required String apiKey,
    String? clientId,
  }) async {
    final clientOptions = ably.ClientOptions(key: apiKey, clientId: clientId);
    final realtime = ably.Realtime(options: clientOptions);

    realtime.connection.on(ably.ConnectionEvent.connected).listen((ably.ConnectionStateChange stateChange) {
      print('État de la connexion en temps réel changé: ${stateChange.event}');
    });

    realtime.connection.on(ably.ConnectionEvent.failed).listen((ably.ConnectionStateChange stateChange) {
      print('Échec de la connexion: ${stateChange.reason}');
    });

    return realtime;
  }

  Future<ably.RealtimeChannel> _createAblyChannelInstance({
    required ably.Realtime realtimeInstance,
    required String channelName,
  }) async {
    final channel = realtimeInstance.channels.get(channelName);
    await channel.attach();

    channel.on(ably.ChannelEvent.failed).listen((ably.ChannelStateChange stateChange) {
      print('Échec de l\'attachement du canal: ${stateChange.reason}');
    });

    return channel;
  }

  void _subscribeToEvent({
    required ably.RealtimeChannel channel,
    String? eventName,
  }) {
    channel.subscribe(name: eventName).listen((ably.Message message) {
      if (mounted) {
        setState(() => displayedMessages.add(message.data.toString()));
      }
      print('Reçu: ${message.data}');
    });
  }

  void _disposeAbly() {
    channel?.detach().catchError((e) {
      print('Erreur lors du détachement du canal: $e');
    });

    realtimeInstance?.close().catchError((e) {
      print('Erreur lors de la fermeture de l\'instance Ably: $e');
    });
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
        title: const Text('Test avec Ably'),
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