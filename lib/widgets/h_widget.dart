// losivio/lib/widgets/homes_widget.dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  List<String> _liveRooms = [];
  bool _isLoading = true;
  final Map<String, LiveController> _liveControllers = {};

  @override
  void initState() {
    super.initState();
    print("[HomeWidget] initState appelé");
    _fetchLiveRooms();
  }

  Future<void> _fetchLiveRooms() async {
    print("[HomeWidget] Début récupération des lives...");
    try {
      final response =
          await http.get(Uri.parse('http://192.168.2.88:9010/live-rooms'));
      print("[HomeWidget] HTTP status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("[HomeWidget] Data reçue: $data");

        setState(() {
          _liveRooms = List<String>.from(data['rooms']);
          _isLoading = false;
        });

        for (var roomId in _liveRooms) {
          print("[HomeWidget] Initialisation du controller pour room: $roomId");
          if (!_liveControllers.containsKey(roomId)) {
            final controller = LiveController(roomId);
            _liveControllers[roomId] = controller;
            controller.connect();
          }
        }
      } else {
        print("[HomeWidget] Erreur serveur: ${response.body}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("[HomeWidget] Erreur récupération des lives: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    print("[HomeWidget] dispose appelé, fermeture des controllers...");
    for (var controller in _liveControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_liveRooms.isEmpty) {
      return const Center(
        child: Text(
          "Aucun live en cours",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
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

class LiveController {
  final String roomId;
  final RTCVideoRenderer renderer = RTCVideoRenderer();
  WebSocketChannel? _channel;
  RTCPeerConnection? _pc;
  String userId = "viewer-${Random().nextInt(100000)}";
  String? consumerId;
  Map<String, dynamic>? rtpCapabilities;

  LiveController(this.roomId);

  Future<void> connect() async {
    print("[LiveController] Initialisation du renderer pour room $roomId");
    await renderer.initialize();

    try {
      print("[LiveController] Connexion WebSocket à ws://192.168.2.88:9010/");
      _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.2.88:9010/'));

      // Rejoindre le live
      _channel!.sink.add(jsonEncode({
        'type': 'joinLive',
        'roomId': roomId,
        'userId': userId,
      }));

      _channel!.stream.listen((message) async {
        print("[LiveController] Message WebSocket reçu: $message");
        final data = jsonDecode(message);

        switch (data['type']) {
          case 'joined':
            print("[LiveController] Spectateur rejoint room ${data['roomId']}");
            // On peut maintenant demander rtpCapabilities
            _channel?.sink.add(jsonEncode({
              'type': 'getRtpCapabilities',
              'roomId': roomId,
              'userId': userId,
            }));
            break;

          case 'rtpCapabilities':
            print("[LiveController] rtpCapabilities reçues");
            rtpCapabilities = data['rtpCapabilities'];
            _requestConsumer();
            break;

          case 'sdpOffer':
            print("[LiveController] sdpOffer reçu");
            consumerId = data['consumerId'];
            await _handleOffer(data['sdp']);
            break;

          case 'iceCandidate':
            print("[LiveController] iceCandidate reçu: ${data['candidate']}");
            if (_pc != null && data['candidate'] != null) {
              final candidate = RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              );
              await _pc!.addCandidate(candidate);
            }
            break;

          default:
            print("[LiveController] Type inconnu: ${data['type']}");
            break;
        }
      });
    } catch (e) {
      print("[LiveController] Erreur connexion WebSocket: $e");
    }
  }

  void _requestConsumer() {
    if (rtpCapabilities != null) {
      print("[LiveController] Demande création consumer pour room $roomId");
      _channel?.sink.add(jsonEncode({
        'type': 'consume',
        'roomId': roomId,
        'userId': userId,
        'rtpCapabilities': rtpCapabilities,
      }));
    }
  }

  Future<void> _handleOffer(String sdp) async {
    try {
      final config = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };

      _pc = await createPeerConnection(config, {});

      await _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      _pc!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          final stream = event.streams[0];
          renderer.srcObject = stream;
          stream.getVideoTracks().forEach((t) => t.enabled = true);
          stream.getAudioTracks().forEach((t) => t.enabled = true);
        }
      };

      _pc!.onIceCandidate = (candidate) {
        if (candidate != null) {
          _channel?.sink.add(jsonEncode({
            'type': 'iceCandidate',
            'roomId': roomId,
            'consumerId': consumerId,
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }));
        }
      };

      await _pc!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);

      _channel?.sink.add(jsonEncode({
        'type': 'sdpAnswer',
        'roomId': roomId,
        'consumerId': consumerId,
        'sdp': answer.sdp,
      }));
    } catch (e) {
      print("[LiveController] Erreur traitement SDP: $e");
    }
  }

  void dispose() {
    renderer.dispose();
    _pc?.close();
    _pc = null;
    _channel?.sink.close();
    _channel = null;
  }
}

class LivePreview extends StatefulWidget {
  final LiveController controller;
  const LivePreview({super.key, required this.controller});

  @override
  State<LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<LivePreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.renderer.onResize = () {
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: widget.controller.renderer.srcObject == null
          ? const Center(child: CircularProgressIndicator())
          : RTCVideoView(
              widget.controller.renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
    );
  }
}
