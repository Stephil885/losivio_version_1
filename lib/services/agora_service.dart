// services/agora_service.dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManager {
  static const String appId = "3a0f5964947c4d19a5ab4a1e3186c493";

  /// 🔹 Initialisation du moteur Agora
  static Future<RtcEngine> initAgora({
    required bool isPublisher,
  }) async {
    // 1️⃣ Permissions
    if (isPublisher) {
      await [Permission.microphone, Permission.camera].request();
    }

    // 2️⃣ Création du moteur
    final RtcEngine engine = createAgoraRtcEngine();

    // 3️⃣ Initialisation Agora
    await engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    // 4️⃣ Définition du rôle client
    await engine.setClientRole(
      role: isPublisher
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    // 5️⃣ Configuration vidéo
    if (isPublisher) {
      await engine.enableVideo();
      await engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 15,
          bitrate: 800,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );
    }

    return engine;
  }

  /// 🔹 Rejoindre un channel Agora
  /// ✅ Utilisation de joinChannelWithUserAccount pour matcher le backend
  static Future<void> joinChannel({
    required RtcEngine engine,
    required String channelId,
    required bool isPublisher,
    required String token,
    required String userAccount, // Ajout de l'ID utilisateur
  }) async {
    if (isPublisher) {
      await engine.startPreview();
    }

    final ChannelMediaOptions options = ChannelMediaOptions(
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      clientRoleType: isPublisher
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
      publishCameraTrack: isPublisher,
      publishMicrophoneTrack: isPublisher,
      autoSubscribeAudio: true,
      autoSubscribeVideo: true,
    );

    // 🔥 Correction : On utilise le UserAccount car le token est lié à cet ID
    await engine.joinChannelWithUserAccount(
      token: token,
      channelId: channelId,
      userAccount: userAccount,
      options: options,
    );
  }

  static Future<void> leaveChannel(RtcEngine engine) async {
    await engine.leaveChannel();
    await engine.stopPreview();
  }

  static Future<void> destroy(RtcEngine engine) async {
    await engine.release();
  }
}