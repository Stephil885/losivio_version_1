import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

//import '../redux/app_state.dart';
import '../widgets/liveStreamer.dart';
import '../models/Streamer_model.dart';
import '../services/live_service.dart';

class BroadcastLivePage extends StatefulWidget {
  final String channelName;
  final RtcEngine engine;
  final int liveId;

  const BroadcastLivePage({
    super.key,
    required this.channelName,
    required this.engine,
    required this.liveId,
  });

  @override
  State<BroadcastLivePage> createState() => _BroadcastLivePageState();
}

class _BroadcastLivePageState extends State<BroadcastLivePage> {
  final List<StreamerModel> _streamers = [];
  bool _isEnding = false;
  int? _localUid;

  late final RtcEngineEventHandler _agoraHandler;

  
  @override
  void initState() {
    super.initState();
    _initAgoraHandlers();
    _publishLocalStream();
  }
/*   final store = StoreProvider.of<AppState>(context, listen: false);
  final user = store.state.user;
  if (user == null) return; */
  /// 🔥 S'assurer que le flux est bien publié
  Future<void> _publishLocalStream() async {
    await widget.engine.enableLocalVideo(true);
    await widget.engine.enableLocalAudio(true);

    await widget.engine.updateChannelMediaOptions(
      const ChannelMediaOptions(
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  /// 🎯 Gestion des événements Agora
  void _initAgoraHandlers() {
    _agoraHandler = RtcEngineEventHandler(
      /// ✅ UID réel du streamer local
      onJoinChannelSuccess: (connection, elapsed) {
        _localUid = connection.localUid;

        if (!mounted) return;

        setState(() {
          _streamers.add(
            StreamerModel(
              uid: _localUid!,
              name: "Moi",
              role: StreamerRole.owner,
              isLocal: true,
            ),
          );
        });
      },

      /// 👥 Utilisateur rejoint (spectateur ou invité)
      onUserJoined: (connection, remoteUid, elapsed) {
        if (!mounted) return;

        setState(() {
          _streamers.add(
            StreamerModel(
              uid: remoteUid,
              name: "Invité",
              role: StreamerRole.participant,
            ),
          );
        });
      },

      /// ❌ Utilisateur quitte
      onUserOffline: (connection, remoteUid, reason) {
        if (!mounted) return;

        setState(() {
          _streamers.removeWhere((s) => s.uid == remoteUid);
        });
      },
    );

    widget.engine.registerEventHandler(_agoraHandler);
  }

  /// 🔴 FIN DU LIVE
  Future<void> _endLive() async {
    if (_isEnding) return;
    _isEnding = true;

    try {
      await LiveService.stopLive(liveId: widget.liveId, streamerId: 42); // Exemple d'ID de streamer
    } catch (e) {
      debugPrint("⚠️ Backend stop error: $e");
    }

    widget.engine.unregisterEventHandler(_agoraHandler);
    await widget.engine.leaveChannel();
    await widget.engine.release();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _endLive();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            /// 🎥 LIVE STREAM
            LiveStreamerPage(
              streamers: _streamers,
              engine: widget.engine,
              channelName: widget.channelName,
            ),

            /// ❌ FIN DU LIVE
            Positioned(
              top: 45,
              right: 20,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                onPressed: _endLive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}