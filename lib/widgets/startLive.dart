// widgets/startLive.dart
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../services/agora_service.dart';
import '../services/live_service.dart';
import '../screens/broadcastLivePage.dart';

class StartLivePage extends StatefulWidget {
  const StartLivePage({super.key});

  @override
  State<StartLivePage> createState() => _StartLivePageState();
}

class _StartLivePageState extends State<StartLivePage>
    with WidgetsBindingObserver {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isStartingLive = false;

  final TextEditingController _titleController = TextEditingController();

  // -------------------- LIFECYCLE --------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPreview();
  }

  Future<void> _initPreview() async {
    _engine = await AgoraManager.initAgora(isPublisher: true);

    // ✅ Preview UNE SEULE FOIS
    await _engine!.startPreview();

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    // ❗ NE PAS release ici si on va en live
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized || _engine == null) return;

    if (state == AppLifecycleState.paused) {
      _engine!.stopPreview();
    } else if (state == AppLifecycleState.resumed) {
      _engine!.startPreview();
    }
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized && _engine != null)
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine!,
                // ✅ PAS de uid pour le local preview
                canvas: const VideoCanvas(),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                _buildStartPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- HEADER --------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: _closePage,
          ),
          IconButton(
            icon: const Icon(
              Icons.flip_camera_ios,
              color: Colors.white,
            ),
            onPressed: () => _engine?.switchCamera(),
          ),
        ],
      ),
    );
  }

  // -------------------- START PANEL --------------------

  Widget _buildStartPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0),
          ],
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: "Titre du live...",
              hintStyle: TextStyle(color: Colors.white60),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isStartingLive ? null : _startLive,
              child: _isStartingLive
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "PASSER EN DIRECT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- ACTIONS --------------------

  Future<void> _startLive() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isStartingLive = true);

    try {
      final result = await LiveService.startLive(title: title);

      final int liveId = result["liveId"];
      final String channelName = result["channelName"];
      final String token = result["token"];
      const String myId = "42";

      await AgoraManager.joinChannel(
        engine: _engine!,
        channelId: channelName,
        isPublisher: true,
        token: token,
        userAccount: myId,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BroadcastLivePage(
              liveId: liveId,
              channelName: channelName,
              engine: _engine!,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Erreur démarrage live: $e");
      setState(() => _isStartingLive = false);
    }
  }

  Future<void> _closePage() async {
    await _engine?.stopPreview();
    await _engine?.release();
    if (mounted) Navigator.pop(context);
  }
}