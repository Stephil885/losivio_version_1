// lib/widgets/discover_widget.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/user_provider.dart';
import '../models/post_model.dart';
import '../providers/posts_provider.dart';
import '../config/api_config.dart';
import '../config/video_cache_manager.dart';
import '../screens/fullscreen_video_page.dart';

// --- CONFIGURATION DESIGN ---
//const Color kBackgroundColor = Color(0xFFF1F5F9);
//const Color kPlaceholderColor = Color(0xFFE2E8F0);
const Color kBackgroundColor = Color(0xFF0F172A); // Bleu nuit très foncé
const Color kPlaceholderColor = Colors.black;    // Noir pur

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

String _formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

// CACHE VIDEO GLOBAL (niveau Big Tech)
final Map<String, VideoPlayerController> preloadControllers = {};
final Map<String, VideoPlayerController> globalVideoCache = {};
final List<String> activeVideos = [];
const int maxActiveVideos = 4;
int visibleVideos = 0;

// --- ÉTAT DE CHARGEMENT : DISCOVER SHIMMER ---
class DiscoverShimmer extends StatelessWidget {
  const DiscoverShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }
}

// --- ÉTAT D'ERREUR ---
class ProfessionalErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const ProfessionalErrorWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "Oups ! Problème de connexion",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: onRetry, child: const Text("Réessayer")),
          ],
        ),
      ),
    );
  }
}

// --- HEADER ---
class ModernHeader extends StatelessWidget {
  const ModernHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: kBackgroundColor.withOpacity(0.8),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            title: ShaderMask(
              shaderCallback: (bounds) => kAccentGradient.createShader(bounds),
              child: const Text(
                'Explorer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, color: Color(0xFF0F172A)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// --- FILTRES ---
class CategoryFilter extends ConsumerWidget {
  const CategoryFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = [
      'TOUT',
      'COMEDIE',
      'POPULAIRE',
      'ART',
      'DESIGN',
      'MUSIQUE',
      'SPORT',
    ];
    final state = ref.watch(postsProvider);
    final userId = ref.watch(userProvider).value?.id;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            bool isSel = state.currentTab.toLowerCase() == cat.toLowerCase();

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => ref
                    .read(postsProvider.notifier)
                    .loadInitialPosts(userId, tab: cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: isSel ? kAccentGradient : null,
                    color: isSel ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSel ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- CARTE IMMERSIVE (AVEC GESTION AUTO-PLAY/PAUSE & CACHE) ---
class ImmersiveCard extends StatefulWidget {
  final PostModel post;
  final List<PostModel> allPosts;
  final int index;

  const ImmersiveCard({
    super.key,
    required this.post,
    required this.allPosts,
    required this.index,
  });

  @override
  State<ImmersiveCard> createState() => _ImmersiveCardState();
}

class _ImmersiveCardState extends State<ImmersiveCard> {
  VideoPlayerController? _controller;
  final ValueNotifier<bool> _isReady = ValueNotifier(false);
  final ValueNotifier<bool> _hasError = ValueNotifier(false);
  bool _isVisible = false;
  bool _isInitializing = false;
  bool _isDisposed = false;
  Timer? _disposeTimer;
  String? _currentUrl;

  @override
  void dispose() {
    if (_isVisible) {
      visibleVideos--;
    }
    if (visibleVideos <= 0) {
      visibleVideos = 0;
      WakelockPlus.disable();
    }
    _disposeTimer?.cancel();
    _isDisposed = true;
    _disposeVideo();
    _isReady.dispose();
    _hasError.dispose();
    super.dispose();
  }

  // --- GESTION DU CACHE MÉMOIRE (ÉVITE LE CRASH) ---
  void _manageCacheSize() {

    const maxCacheVideos = 10;
    while (activeVideos.length > maxCacheVideos) {
      final oldestUrl = activeVideos.first;

      // ⭐ Ne jamais supprimer la vidéo actuelle
      if (oldestUrl == _currentUrl) {
        activeVideos.removeAt(0);
        activeVideos.add(oldestUrl);
        continue;
      }

      final controllerToDispose = globalVideoCache.remove(oldestUrl);

      if (controllerToDispose != null) {
        controllerToDispose.pause();
        controllerToDispose.dispose();
        debugPrint("Cache sécurisé : suppression -> $oldestUrl");
      }

      activeVideos.remove(oldestUrl);
    }
  }

  Future<void> _disposeVideo() async {
    _disposeTimer?.cancel();
    _disposeTimer = Timer(const Duration(seconds: 8), () async {
      if (_controller == null || _currentUrl == null) return;
      if (_isVisible) return; // Si l'utilisateur est revenu dessus, on stop
      
      // On met en pause au lieu de tout supprimer visuellement
      if (_controller!.value.isPlaying) {
        await _controller!.pause();
      }

      // N'enlève PAS _isReady.value = false ici ! 
      // C'est ça qui cause le "nuage" gris pendant le scroll.
      
      debugPrint("Vidéo mise en sommeil (mais reste affichée)");
    });
  }

  Future<void> _initializeVideo() async {
    if (!_isVisible || !mounted || _isInitializing) return;

    if (_controller != null &&
        _currentUrl != null &&
        _controller!.value.isInitialized &&
        globalVideoCache.containsKey(_currentUrl)) {
      return;
    }
    _isInitializing = true;
    _hasError.value = false;

    if (widget.post.medias.isEmpty || widget.post.medias.first.mediaType != 'video') {
      _isInitializing = false;
      return;
    }

    final url = widget.post.medias.first.url;
    _currentUrl = url;

    // 1. Récupération (Cache Global ou Preload)
    if (globalVideoCache.containsKey(url)) {
      _controller = globalVideoCache[url];
    } else if (preloadControllers.containsKey(url)) {
      _controller = preloadControllers.remove(url);
      if (_controller != null) {
        globalVideoCache[url] = _controller!;
        if (!activeVideos.contains(url)) {
          activeVideos.add(url);
        }
        _manageCacheSize();
      }
    }

    // 2. Si on a trouvé un contrôleur, on l'utilise
    if (_controller != null) {
      _playWhenReady();
      _isInitializing = false;
      return;
    }

    // 3. Sinon, initialisation complète (fallback)
    try {
      final file = await VideoCacheManager.instance.getSingleFile(url);
      if (!mounted || !_isVisible || _isDisposed) return;

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);

      // ⭐ Warmup decoding
      await controller.play();
      await Future.delayed(const Duration(milliseconds: 50));
      await controller.pause();
      await controller.seekTo(Duration.zero);

      globalVideoCache[url] = controller;

      if (!activeVideos.contains(url)) {
        activeVideos.add(url);
      }

      _manageCacheSize();

      _controller = controller;
      _playWhenReady();
      _preloadNext();

    } catch (e) {
      debugPrint("Video error $e");
      if (mounted) _hasError.value = true;
    } finally {
      _isInitializing = false;
    }
  }

  void _playWhenReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller != null && _controller!.value.isInitialized && _isVisible && !_isDisposed) {
        _isReady.value = true;
        _controller!.play();
      }
    });
  }

  void _preloadNext() {
    final nextIndex = widget.index + 1;
    if (nextIndex < widget.allPosts.length) {
      final nextPost = widget.allPosts[nextIndex];
      if (nextPost.medias.isNotEmpty && nextPost.medias.first.mediaType == 'video') {
        _preloadNextVideo(nextPost.medias.first.url);
      }
    }
  }

  Future<void> _preloadNextVideo(String url) async {
    if (globalVideoCache.containsKey(url) || preloadControllers.containsKey(url)) return;

    if (preloadControllers.length >= 3) {
      final oldestUrl = preloadControllers.keys.first;
      preloadControllers.remove(oldestUrl)?.dispose();
    }

    try {
      final file = await VideoCacheManager.instance.getSingleFile(url);

      final controller = VideoPlayerController.file(file);

      await controller.initialize();

      await controller.setVolume(0);

      // ⭐ SECRET TIKTOK : Warm-up decoding
      await controller.play();
      await Future.delayed(const Duration(milliseconds: 80));
      await controller.pause();
      await controller.seekTo(Duration.zero);

      preloadControllers[url] = controller;

      debugPrint("Preload + Warmup OK → $url");

    } catch (_) {}
  }

  void _handleNavigation(BuildContext context) async {
    _controller?.pause();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenVideoPage(
          posts: widget.allPosts,
          initialIndex: widget.index,
        ),
      ),
    );
    if (mounted && _isVisible) _controller?.play();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.post.medias.firstOrNull;
    final imageUrl = (media?.mediaType == 'video') 
        ? (media?.thumbnailUrl ?? '') 
        : (media?.url ?? '');

    return VisibilityDetector(
      key: ValueKey("vis_${widget.post.id}"),
      onVisibilityChanged: (info) {

        if (info.visibleFraction > 0.6) {

          if (!_isVisible) {
            visibleVideos++;
          }
          _isVisible = true;
          if (visibleVideos > 0) {
            WakelockPlus.enable();
          }
          _initializeVideo();
        } else {
          if (_isVisible) {
            visibleVideos--;
          }
          _isVisible = false;
          if (visibleVideos <= 0) {
            WakelockPlus.disable();
            visibleVideos = 0;
          }
          _controller?.pause();
          _disposeVideo();
        }
      },
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: () => _handleNavigation(context),
            child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: kPlaceholderColor,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. MINIATURE (Toujours là en fond)
                if (imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    placeholder: (_, __) => Container(color: kPlaceholderColor),
                    errorWidget: (_, __, ___) => Container(color: kPlaceholderColor),
                  )
                else
                  Container(color: kPlaceholderColor),

                // 2. VIDÉO
                _buildAnimatedVideo(),

                // 3. ETAT D'ERREUR
                /* ValueListenableBuilder<bool>(
                  valueListenable: _hasError,
                  builder: (context, hasError, _) {
                    if (!hasError) return const SizedBox.shrink();
                    return _buildErrorUI();
                  },
                ), */

                // 4. OVERLAY DESIGN (Gradient)
                const _BottomGradient(),

                // 5. INFOS DU POST
                Positioned(
                  bottom: 12, 
                  left: 12, 
                  right: 12,
                  child: _buildInfoOverlay(),
                ),
              ],
            ),
          ),
        ),
        ),
    );
  }

  Widget _buildAnimatedVideo() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isReady,
      builder: (context, ready, child) {
        final controller = _controller;

        // ON GARDE LA VIDÉO MORTE OU VIVE : 
        // On retire " || !_isVisible " de la condition ci-dessous
        if (!ready ||
            controller == null ||
            !controller.value.isInitialized ||
            !globalVideoCache.containsKey(_currentUrl)) {
          return const SizedBox.shrink();
        }

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: 1.0,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: GestureDetector(
        onTap: _initializeVideo,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildInfoOverlay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildStatItem(
              Icons.remove_red_eye_rounded,
              _formatCount(widget.post.viewsCount),
            ),
            const SizedBox(width: 12),
            _buildStatItem(
              Icons.favorite_rounded,
              _formatCount(widget.post.likesCount),
              color: widget.post.isLiked ? Colors.pinkAccent : Colors.white70,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildAvatar(widget.post.authorAvatar, widget.post.authorName),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "@${widget.post.authorName}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label, {
    Color color = Colors.white70,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? url, String? username) {
    final bool hasUrl = url != null && url.isNotEmpty;
    final String fullUrl = hasUrl ? "${ApiConfig.avatarUrl}/$url" : "";
    final String initial =
        (username != null && username.isNotEmpty)
            ? username[0].toUpperCase()
            : '?';

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: kAccentGradient,
      ),
      child: CircleAvatar(
        radius: 11,
        backgroundColor: Colors.blueGrey[400],
        child: ClipOval(
          child:
              hasUrl
                  ? CachedNetworkImage(
                    imageUrl: fullUrl,
                    fit: BoxFit.cover,
                    width: 22,
                    height: 22,
                    errorWidget:
                        (_, __, ___) => Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                  )
                  : Text(
                    initial,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
        ),
      ),
    );
  }
}

// Widget interne pour le gradient (plus propre)
class _BottomGradient extends StatelessWidget {
  const _BottomGradient();
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center, // <-- S'arrête au milieu au lieu de monter si haut
          colors: [
            Colors.black54, // <-- Moins opaque (54% au lieu de 87%)
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}