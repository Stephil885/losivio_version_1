// lib/home_widget.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  List<String> _liveRooms = [];
  bool _isLoading = true;
  final Map<String, LiveController> _liveControllers = {};
  late WebSocketChannel _channel;
  late Stream<dynamic> _broadcastStream;

  @override
  void initState() {
    super.initState();
    _setupWebSocketListener();
    _fetchLiveRooms();
  }

  Future<void> _fetchLiveRooms() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.2.88:9010/live-rooms'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _liveRooms = List<String>.from(data['rooms'].map((r) => r['roomId']));
      }
    } catch (e) {
      print("❌ Erreur récupération des lives: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
      for (var roomId in _liveRooms) {
        if (!_liveControllers.containsKey(roomId)) {
          final controller =
              LiveController(roomId, _broadcastStream, _channel.sink);
          _liveControllers[roomId] = controller;
          controller.connect();
        }
      }
    }
  }

  void _setupWebSocketListener() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.2.88:9010/socket'),
    );
    _broadcastStream = _channel.stream.asBroadcastStream();

    _broadcastStream.listen((message) {
      final data = jsonDecode(message);
      final type = data['type'];

      if (type == 'liveStarted') {
        final roomId = data['roomId'];
        if (!_liveRooms.contains(roomId)) {
          setState(() => _liveRooms.add(roomId));
          final controller =
              LiveController(roomId, _broadcastStream, _channel.sink);
          _liveControllers[roomId] = controller;
          controller.connect();
        }
      } else if (type == 'liveEnded') {
        final roomId = data['roomId'];
        if (_liveRooms.contains(roomId)) {
          setState(() => _liveRooms.remove(roomId));
          _liveControllers[roomId]?.dispose();
          _liveControllers.remove(roomId);
        }
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _liveControllers.values) {
      controller.dispose();
    }
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_liveRooms.isEmpty) {
      return const Center(
        child: Text("Aucun live en cours",
            style: TextStyle(color: Colors.white, fontSize: 18)),
      );
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _liveRooms.length,
      itemBuilder: (context, index) {
        final roomId = _liveRooms[index];
        return LivePreview(controller: _liveControllers[roomId]!);
      },
    );
  }
}

// --------------------------------------------------
// 🎬 Contrôleur Live (Spectateur)
// --------------------------------------------------

class LiveController {
  final String roomId;
  final Stream<dynamic> _broadcastStream;
  final WebSocketSink _sink;
  final RTCVideoRenderer renderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  final String userId = 'viewer-${const Uuid().v4()}';

  LiveController(this.roomId, this._broadcastStream, this._sink);

  Future<void> connect() async {
    print("🔌 [$roomId] Connexion du spectateur $userId...");
    await renderer.initialize();

    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _pc = await createPeerConnection(config, {});
    print("✅ PeerConnection créée");

    // -----------------------------
    // 💡 Écouter tous les flux reçus
    // -----------------------------
    _pc!.onTrack = (event) {
      print("🎥 Flux reçu: kind=${event.track.kind}, id=${event.track.id}");
      if (event.streams.isNotEmpty) {
        renderer.srcObject = event.streams[0];
      }
    };

    // Recevoir uniquement
    _pc!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    _pc!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    // Créer l’offre SDP
    RTCSessionDescription offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    // Envoyer la requête joinLive avec l’offer SDP
    _sink.add(jsonEncode({
      'type': 'joinLive',
      'roomId': roomId,
      'userId': userId,
      'sdp': offer.sdp,
      'sdpType': offer.type,
    }));

    // Écoute des messages du serveur
    _broadcastStream.listen((message) async {
      final data = jsonDecode(message);
      if (data['roomId'] != roomId) return;

      switch (data['type']) {
        case 'sdpAnswer':
          final sdp = data['sdp'];
          if (_pc != null) {
            await _pc!.setRemoteDescription(
              RTCSessionDescription(sdp, 'answer'),
            );
            print("▶️ [$roomId] Flux démarré ✅");
          }
          break;

        case 'iceCandidate':
          final candidate = data['candidate'];
          if (_pc != null && candidate != null) {
            await _pc!.addCandidate(RTCIceCandidate(
              candidate['candidate'],
              candidate['sdpMid'],
              candidate['sdpMLineIndex'],
            ));
          }
          break;

        default:
          break;
      }
    });
  }

  void dispose() {
    renderer.srcObject = null;
    renderer.dispose();
    _pc?.close();
  }
}

// --------------------------------------------------
// 🎥 Widget d’affichage vidéo
// --------------------------------------------------

class LivePreview extends StatefulWidget {
  final LiveController controller;
  const LivePreview({super.key, required this.controller});

  @override
  State<LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<LivePreview> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: widget.controller.renderer.srcObject == null
          ? const Center(
              child: Text(
                "⏳ En attente du flux...",
                style: TextStyle(color: Colors.white),
              ),
            )
          : RTCVideoView(
              widget.controller.renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
    );
  }
}