// lib/config/video_cache_manager.dart

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheManager {
  static const key = 'videoCacheKey';
  
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // Supprime après 7 jours
      maxNrOfCacheObjects: 100,             // Garde max 100 vidéos
      repo: JsonCacheInfoRepository(databaseName: key),
    ),
  );
}