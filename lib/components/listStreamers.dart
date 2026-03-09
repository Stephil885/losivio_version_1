/* // components/listStreamers.dart

import '../models/Streamer_model.dart';

final List<List<StreamerMock>> liveStreams = [
  /// 1. 🔴 LIVE SOLO - Star du show
  [
    StreamerMock(id: 101, image: 'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4', role: StreamerRole.owner),
  ],

  /// 2. 🔴 LIVE DUO - Owner + VIP (Match)
  [
    StreamerMock(id: 201, image: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4', role: StreamerRole.owner),
    StreamerMock(id: 202, image: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4', role: StreamerRole.vip),
  ],

  /// 3. 🔴 LIVE TRIO - Discussion
  [
    StreamerMock(id: 301, image: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4', role: StreamerRole.owner),
    StreamerMock(id: 302, image: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4', role: StreamerRole.participant),
    StreamerMock(id: 303, image: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4', role: StreamerRole.participant),
  ],

  /// 4. 🔴 LIVE QUAD - Gaming / Collab
  [
    StreamerMock(id: 401, image: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4', role: StreamerRole.owner),
    StreamerMock(id: 402, image: 'https://storage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4', role: StreamerRole.vip),
    StreamerMock(id: 403, image: 'https://storage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackAds.mp4', role: StreamerRole.participant),
    StreamerMock(id: 404, image: 'https://storage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4', role: StreamerRole.participant),
  ],

]; */