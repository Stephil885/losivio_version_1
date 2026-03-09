// models/Streamer_model.dart

// role = host(admin), moderator(invité), vip(premium)

enum StreamerRole { owner, participant, vip}

class StreamerModel {
  final int uid;
  final String name; 
  final StreamerRole role;
  final bool isLocal;
  final bool audioEnabled;
  final bool videoEnabled;

  const StreamerModel({
    required this.uid,
    required this.name,
    required this.role,
    this.isLocal = false,
    this.audioEnabled = true,
    this.videoEnabled = true,
  });

  StreamerModel copyWith({
    int? uid,
    String? name,
    StreamerRole? role,
    bool? isLocal,
    bool? audioEnabled,
    bool? videoEnabled,
  }) {
    return StreamerModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      role: role ?? this.role,
      isLocal: isLocal ?? this.isLocal,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      videoEnabled: videoEnabled ?? this.videoEnabled,
    );
  }
}