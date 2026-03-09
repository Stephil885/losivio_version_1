// lib/screens/liveSpectateurPage.dart

import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../widgets/liveSpectateur.dart';
import '../models/Streamer_model.dart';
import '../services/agora_service.dart';

class LiveSpectateurPage extends StatefulWidget {
  final String channelName;

  const LiveSpectateurPage({
    super.key,
    required this.channelName,
  });

  @override
  State<LiveSpectateurPage> createState() => _LiveSpectateurPageState();
}

class _LiveSpectateurPageState extends State<LiveSpectateurPage> {
  late RtcEngine _engine;
  final List<StreamerModel> _streamers = [];
  bool _isLeaving = false;
  bool _isEngineReady = false; // 🔹 indicateur engine prêt

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    /// 🎭 INITIALISATION EN MODE SPECTATEUR
    _engine = await AgoraManager.initAgora( isPublisher: false);

    /// 🔕 DESACTIVER AUDIO/VIDEO LOCAL
    await _engine.enableLocalAudio(false);
    await _engine.enableLocalVideo(false);

    /// 🎧 REJOINDRE LE CHANNEL EN MODE AUDIENCE
    await AgoraManager.joinChannel(
      engine: _engine,
      channelId: widget.channelName,
      isPublisher: false,
      token: "", // Pas de token pour les spectateurs
      userAccount: "spectator_123", // ID utilisateur fictif pour le spectateur
    );

    /// 📌 HANDLERS
    _initAgoraHandlers();

    /// ✅ engine prêt
    if (mounted) {
      setState(() {
        _isEngineReady = true;
      });
    }
  }

  void _initAgoraHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        /// 🎥 STREAMER DÉTECTÉ
        onRemoteVideoStateChanged: (
          connection,
          remoteUid,
          state,
          reason,
          elapsed,
        ) async {
          if (state != RemoteVideoState.remoteVideoStateDecoding) return;

          if (_streamers.any((s) => s.uid == remoteUid)) return;

          debugPrint("Flux vidéo actif: $remoteUid");

          /// ⚠️ CORRECTION : setupRemoteVideo avec VideoViewController
          await _engine.setupRemoteVideo(
            VideoCanvas(
              uid: remoteUid,
              renderMode: RenderModeType.renderModeHidden, // ✅ au lieu de VideoRenderModeType.videoRenderModeHidden
            ),
          );


          if (!mounted) return;

          setState(() {
            _streamers.add(
              StreamerModel(
                uid: remoteUid,
                name: "Streamer",
                role: _streamers.isEmpty
                    ? StreamerRole.owner
                    : StreamerRole.participant,
              ),
            );
          });
        },

        /// ❌ STREAMER PARTI
        onUserOffline: (connection, remoteUid, reason) {
          debugPrint("Streamer parti: $remoteUid");
          setState(() {
            _streamers.removeWhere((s) => s.uid == remoteUid);
          });
        },

        onLeaveChannel: (connection, stats) {
          debugPrint("Spectateur quitté le live");
        },
      ),
    );
  }

  /// 🔹 Nettoyage
  Future<void> _cleanup() async {
    if (_isLeaving) return;
    _isLeaving = true;

    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) await _cleanup();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            /// 🎥 UI LIVE ou loader
            _isEngineReady
                ? LivePage(
                    streamers: _streamers,
                    engine: _engine,
                    channelName: widget.channelName,
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

            /// ❌ Bouton quitter
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
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
