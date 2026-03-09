import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _previewRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _isStreaming = false;

  final String signalingServer = "ws://192.168.2.88:9010/webrtc";
  final String backendBaseUrl = "http://192.168.2.88:9010";
  WebSocketChannel? _wsChannel;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _connectSignaling();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _previewRenderer.initialize();

    // ATTACHER le flux après le build pour éviter le freeze
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': {'facingMode': 'user', 'width': 1280, 'height': 720},
        'audio': true,
      });

      _localRenderer.srcObject = _localStream;
      _previewRenderer.srcObject = _localStream;

      setState(() {}); // Force le rebuild pour afficher la vidéo
    });
  }

  void _connectSignaling() {
    _wsChannel = WebSocketChannel.connect(Uri.parse(signalingServer));

    _wsChannel!.stream.listen((message) async {
      final data = jsonDecode(message);
      if (_peerConnection == null) return;

      if (data['type'] == 'candidate') {
        final candidate = RTCIceCandidate(
            data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
        await _peerConnection!.addCandidate(candidate);
      }
    }, onDone: () => print("WebSocket fermé"),
       onError: (e) => print("WebSocket error: $e"));
  }

  void _sendSignaling(Map<String, dynamic> data) {
    _wsChannel?.sink.add(jsonEncode(data));
  }

  Future<void> _startLiveOnServer() async {
    try {
      final res = await http.get(Uri.parse("$backendBaseUrl/live/start"));
      if (res.statusCode == 200) print("✅ Live démarré sur le serveur");
    } catch (e) {
      print("⚠️ Erreur startLive: $e");
    }
  }

  Future<void> _stopLiveOnServer() async {
    try {
      final res = await http.get(Uri.parse("$backendBaseUrl/live/stop"));
      if (res.statusCode == 200) print("✅ Live arrêté sur le serveur");
    } catch (e) {
      print("⚠️ Erreur stopLive: $e");
    }
  }

  Future<void> _startStreaming() async {
    if (_isStreaming || _localStream == null) return;
    await _startLiveOnServer();

    final configuration = {'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]};
    _peerConnection = await createPeerConnection(configuration);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onIceCandidate = (RTCIceCandidate? c) {
      if (c != null) {
        _sendSignaling({
          'type': 'candidate',
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex
        });
      }
    };

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _sendSignaling({'type': 'offer', 'sdp': offer.sdp});

    setState(() => _isStreaming = true);
  }

  Future<void> _stopStreaming() async {
    if (!_isStreaming) return;
    await _stopLiveOnServer();
    await _peerConnection?.close();
    _peerConnection = null;
    setState(() => _isStreaming = false);
  }

  @override
  void dispose() {
    _stopStreaming();
    _localStream?.dispose();
    _localRenderer.dispose();
    _previewRenderer.dispose();
    _wsChannel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video plein écran
          Positioned.fill(
            child: _localRenderer.srcObject == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    key: UniqueKey(),
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
          ),
          // Petite preview locale
          Positioned(
            top: 40,
            right: 20,
            width: 150,
            height: 200,
            child: _previewRenderer.srcObject == null
                ? const SizedBox.shrink()
                : RTCVideoView(
                    _previewRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
          ),
          // Boutons démarrer / arrêter
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isStreaming ? null : _startStreaming,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Démarrer le Live"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _isStreaming ? _stopStreaming : null,
                  icon: const Icon(Icons.stop),
                  label: const Text("Arrêter"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
