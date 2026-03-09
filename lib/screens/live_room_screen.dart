import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LiveRoomScreen extends StatefulWidget {
  final String roomId;
  const LiveRoomScreen({super.key, required this.roomId});

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  bool _isStreaming = false;

  late WebSocketChannel _channel;
  final String _userId = const Uuid().v4();
  RTCPeerConnection? _pc;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  // Vérifie et demande les permissions caméra/micro
  Future<void> _checkPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      throw Exception("Permissions caméra/micro non accordées");
    }
  }

  // Initialisation de la vidéo et connexion WebSocket
  Future<void> _initRenderer() async {
    await _localRenderer.initialize();
    await _checkPermissions();
    await _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.2.88:9010/socket'),
    );

    _channel.stream.listen((message) async {
      final data = jsonDecode(message);

      switch (data['type']) {
        // Le serveur a créé un transport, on peut maintenant produire le flux
        case 'transportCreated':
          await _produceTracks();
          break;

        // Le transport est connecté
        case 'transportConnected':
          print("✅ Transport connecté côté serveur.");
          break;

        // Le serveur a créé le Producer
        case 'produced':
          print('🎥 Producer créé avec succès.');
          break;

        // Réponse SDP du serveur
        case 'sdpAnswer':
          final sdp = data['sdp'];
          await _pc?.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
          print("🎯 SDP Answer appliquée !");
          break;

        default:
          break;
      }
    });

    print("🔗 WebSocket connecté à ton serveur Mediasoup");
  }

  // Lance la diffusion
  Future<void> _startStreaming() async {
    if (_isStreaming) return;
    setState(() => _isStreaming = true);

    try {
      // Démarre la capture locale
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': true,
      });

      if (_localStream!.getVideoTracks().isEmpty) {
        throw Exception("Aucune piste vidéo détectée !");
      }

      print("🎬 Capture démarrée");
      print("Pistes vidéo: ${_localStream!.getVideoTracks().length}");
      print("Pistes audio: ${_localStream!.getAudioTracks().length}");

      if (!mounted) return;
      setState(() {
        _localRenderer.srcObject = _localStream;
      });

      // Crée le transport côté serveur pour la diffusion
      _channel.sink.add(jsonEncode({
        'type': 'createTransport',
        'userId': _userId,
        'roomId': widget.roomId,
      }));

    } catch (e) {
      print("❌ Erreur démarrage live: $e");
      if (mounted) setState(() => _isStreaming = false);
    }
  }


  // Envoie l’offre SDP au serveur
  Future<void> _produceTracks() async {
    if (_localStream == null) return;

    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _pc = await createPeerConnection(config, {});

    // Ajoute les pistes locales
    for (var track in _localStream!.getTracks()) {
      _pc!.addTrack(track, _localStream!);
    }

    // Crée l'offre SDP locale
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    print("📡 Offre SDP générée (${offer.sdp!.length} caractères)");

    // Envoie au backend pour qu'il crée un Producer
    _channel.sink.add(jsonEncode({
      'type': 'produce',
      'userId': _userId,
      'roomId': widget.roomId,
      'sdp': offer.sdp,
    }));
  }

  // Stoppe proprement le live
  Future<void> _stopStreaming() async {
    try {
      _localStream?.getTracks().forEach((track) => track.stop());
      _localRenderer.srcObject = null;
      await _pc?.close();
      await _channel.sink.close();
    } catch (_) {}
    setState(() => _isStreaming = false);
  }

  @override
  void dispose() {
    _stopStreaming();
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Room: ${widget.roomId}"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: RTCVideoView(
                _localRenderer,
                mirror: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(_isStreaming ? Icons.stop : Icons.videocam),
              label: Text(
                _isStreaming ? "Arrêter la diffusion" : "Démarrer la diffusion",
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: _isStreaming ? Colors.red : Colors.green,
              ),
              onPressed: _isStreaming ? _stopStreaming : _startStreaming,
            ),
          ),
        ],
      ),
    );
  }
}
