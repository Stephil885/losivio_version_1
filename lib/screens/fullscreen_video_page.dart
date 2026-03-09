// /screens/fullscreen_video_page.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../providers/user_provider.dart';
import '../providers/posts_provider.dart';
import '../models/post_model.dart';
import '../models/ActionIconSetting.dart';
import '../models/ActionIcon.dart';
import '../models/commentsSheet.dart';

class FullscreenVideoPage extends ConsumerStatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;

  const FullscreenVideoPage({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  ConsumerState<FullscreenVideoPage> createState() =>
      _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends ConsumerState<FullscreenVideoPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _preloadedControllers = {};
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    _pageController = PageController(initialPage: widget.initialIndex);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _preloadVideo(_currentIndex);
    _preloadVideo(_currentIndex + 1);
    _preloadVideo(_currentIndex - 1);
  }

  @override
  void dispose() {
    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _preloadVideo(int index) async {
    if (index < 0 || index >= widget.posts.length) return;
    if (_preloadedControllers.containsKey(index)) return;

    final media = widget.posts[index].medias.firstOrNull;
    if (media == null) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(media.url));

    try {
      await controller.initialize();
      await controller.setLooping(true);

      _preloadedControllers[index] = controller;
    } catch (e) {
      debugPrint("Preload error: $e");
    }
  }

  void _cleanupControllers() {
    final keysToRemove = <int>[];
    for (final entry in _preloadedControllers.entries) {
      final index = entry.key;

      if (index < _currentIndex - 1 || index > _currentIndex + 1) {
        entry.value.dispose();
        keysToRemove.add(index);
      }
    }
    for (final key in keysToRemove) {
      _preloadedControllers.remove(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.value;
    final posts = widget.posts;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical, // Défilement vertical
        itemCount: posts.length,
        onPageChanged: (index) {
          _currentIndex = index;
          _preloadVideo(index + 1);
          _preloadVideo(index - 1);
          _cleanupControllers();

          setState(() {});
        },
        itemBuilder: (context, index) {
          // On ne joue la vidéo que si c'est la page active
          final post = posts[index];

          return VideoFeedItem(
            post: post,
            isActive: index == _currentIndex,
            preloadedController: _preloadedControllers[index],
            currentUserId: user?.id,
            onToggleFollow:
                user == null
                    ? null
                    : () => ref
                        .read(postsProvider.notifier)
                        .toggleFollow(post.authorId, user.id),
            onDoubleTapLike:
                user == null
                    ? null
                    : () => ref
                        .read(postsProvider.notifier)
                        .toggleLike(post.id, user.id, post.authorId),
          );
        },
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// WIDGET INDIVIDUEL POUR CHAQUE VIDÉO
////////////////////////////////////////////////////////

class VideoFeedItem extends ConsumerStatefulWidget {
  final PostModel post;
  final bool isActive;
  final VideoPlayerController? preloadedController;
  final int? currentUserId;
  final VoidCallback? onToggleFollow;
  final VoidCallback? onDoubleTapLike;
  

  const VideoFeedItem({
    super.key,
    required this.post,
    required this.isActive,
    this.preloadedController,
    this.currentUserId,
    this.onToggleFollow,
    this.onDoubleTapLike,
  });

  @override
  ConsumerState<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends ConsumerState<VideoFeedItem>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _showControls = false;
  bool _showHeart = false;
  bool _viewRegistered = false;
  Timer? _hideTimer;

  late AnimationController _uiAnimationController;
  late AnimationController _musicDiscController;

  @override
  void initState() {
    super.initState();
    _uiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _musicDiscController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _initVideo();
  }

  // ✅ LOGIQUE DE DÉTECTION DE VUE
  void _videoListener() {
    if (!mounted || _viewRegistered || _controller == null || widget.currentUserId == null) return;

    // Si l'utilisateur a regardé plus de 3 secondes
    if (_controller!.value.position.inSeconds >= 3) {
      _viewRegistered = true; // On marque comme fait localement
      
      final mediaId = widget.post.medias.firstOrNull?.id;
      if (mediaId != null) {
        // Appeler le provider pour enregistrer en DB
        ref.read(postsProvider.notifier).registerView(
          postId: widget.post.id,
          mediaId: mediaId,
          watchTime: 3,
          userId: widget.currentUserId!,
        );
      }
    }
  }

  @override
  void didUpdateWidget(VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Gestion du Play/Pause quand on change de page
    if (_controller != null && _controller!.value.isInitialized) {
      if (widget.isActive) {
        _controller!.setVolume(1);
        _controller!.play();

      } else {
        _controller!.pause();
        _controller!.setVolume(0);

      }

    }
  }

  Future<void> _initVideo() async {
    if (widget.preloadedController != null) {
      _controller = widget.preloadedController;
    } else {
      final media = widget.post.medias.firstOrNull;
      if (media == null) return;
      _controller = VideoPlayerController.networkUrl(Uri.parse(media.url));
      try {
        await _controller!.initialize();
        await _controller!.setLooping(true);
      } catch (e) {
        debugPrint("Erreur video : $e");
      }
    }

    if (_controller != null) {
      _controller!.addListener(_videoListener); // ✅ On attache l'écouteur de vue
      if (widget.isActive) await _controller!.play();
      if (mounted) setState(() => _isReady = true);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_videoListener); // ✅ On retire l'écouteur
    // Dispose seulement si ce n'est PAS un controller preload
    if (widget.preloadedController == null) {
      _controller?.dispose();
    }
    _uiAnimationController.dispose();
    _musicDiscController.dispose();
    super.dispose();
  }

  void _onTapVideo() {
    setState(() => _showControls = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
    if (_controller == null) return;
    _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        /// 1. VIDEO
        _buildVideoBackground(),
        /// 2. GRADIENTS
        _buildGradients(),
        /// 3. BOUTON RETOUR
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          child: _buildBlurIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),

        /// 4. ACTIONS DROITE
        Positioned(
          right: 15,
          bottom: 60,
          child: FadeTransition(
            opacity: _uiAnimationController,
            child: _RightActionsColumn(
              post: widget.post,
              currentUserId: widget.currentUserId,
              onFollowTap: widget.onToggleFollow ?? () {},
              onLikeTap: widget.onDoubleTapLike ?? () {},
            ),
          ),
        ),

        /// 5. INFOS AUTEUR
        Positioned(
          left: 20,
          bottom: 40,
          right: 90,
          child: FadeTransition(
            opacity: _uiAnimationController,
            child: _buildAuthorInfo(),
          ),
        ),

        /// 6. PROGRESS BAR
        Positioned(bottom: 0, left: 0, right: 0, child: _buildProgressBar()),
        /// ❤️ COEUR LIKE
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showHeart ? 1 : 0,
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 120,
          ),
        ),
        /// 7. FEEDBACK PLAY/PAUSE
        _buildPlayFeedback(),
      ],
    );
  }

  // --- LES MÉTHODES DE CONSTRUCTION (Repris de ton code initial) ---

  Widget _buildVideoBackground() {
    return Container(
      color: Colors.black,
      child:
          _isReady && _controller != null
              ? GestureDetector(
                  onTap: _onTapVideo,
                  onDoubleTap: () {
                    setState(() => _showHeart = true);
                    widget.onDoubleTapLike?.call();
                    Future.delayed(const Duration(milliseconds: 700), () {
                      if (mounted) {
                        setState(() => _showHeart = false);
                      }
                    });

                  },
                child: _VideoPlayerView(controller: _controller!),
              )
              : const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white24,
                ),
              ),
    );
  }

  Widget _buildGradients() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
              stops: const [0.0, 0.15, 0.65, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlurIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white.withOpacity(0.12),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSideActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionItem(
          Icons.favorite_rounded,
          widget.post.likesCount.toString(),
        ),
        const SizedBox(height: 25),
        _buildActionItem(
          Icons.chat_bubble_rounded,
          widget.post.commentsCount.toString(),
        ),
        const SizedBox(height: 25),
        _buildActionItem(Icons.share_rounded, "Share"),
        const SizedBox(height: 25),
        const ActionIconSetting(icon: Icons.more_horiz_rounded),
        const SizedBox(height: 35),
        RotationTransition(
          turns: _musicDiscController,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [Colors.black, Colors.grey.shade800, Colors.black],
              ),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 32,
          shadows: const [Shadow(blurRadius: 10, color: Colors.black45)],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                widget.post.authorAvatar ?? "https://i.pravatar.cc/150",
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                "@${widget.post.authorName}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white70),
              ),
              child: const Text(
                "Follow",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.post.medias.isNotEmpty)
          Text(
            widget.post.medias.first.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (_controller == null) return const SizedBox();
    return ValueListenableBuilder(
      valueListenable: _controller!,
      builder: (context, VideoPlayerValue value, child) {
        if (!value.isInitialized) return const SizedBox();
        final progress =
            value.position.inMilliseconds / value.duration.inMilliseconds;
        return LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.05),
          valueColor: const AlwaysStoppedAnimation(Colors.cyanAccent),
          minHeight: 1.5,
        );
      },
    );
  }

  Widget _buildPlayFeedback() {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _showControls ? 1 : 0,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black12,
          ),
          child: Icon(
            _controller?.value.isPlaying ?? false
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            size: 60,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}

class _VideoPlayerView extends StatelessWidget {
  final VideoPlayerController controller;
  const _VideoPlayerView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
/* -------------------------------------------------------------------------- */
/* RIGHT ACTIONS COLUMN                                                       */
/* -------------------------------------------------------------------------- */
class _RightActionsColumn extends ConsumerStatefulWidget {
  final PostModel post;
  final int? currentUserId;
  final VoidCallback onFollowTap;
  final VoidCallback onLikeTap;

  const _RightActionsColumn({
    required this.post,
    this.currentUserId,
    required this.onFollowTap,
    required this.onLikeTap,
  });

  @override
  ConsumerState<_RightActionsColumn> createState() => _RightActionsColumnState();
}

class _RightActionsColumnState extends ConsumerState<_RightActionsColumn>
    with SingleTickerProviderStateMixin {
  late AnimationController _musicDiscController;

  @override
  void initState() {
    super.initState();
    _musicDiscController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(); // rotation infinie
  }

  @override
  void dispose() {
    _musicDiscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 LA MAGIE EST ICI : On cherche le post à jour dans le provider.
    // S'il ne le trouve pas, il garde le widget.post initial en secours.
    final currentPost = ref.watch(postsProvider).posts.firstWhere(
          (p) => p.id == widget.post.id,
          orElse: () => widget.post,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Avatar(
          key: ValueKey('avatar_${currentPost.authorId}_${currentPost.authorAvatar}'),
          userId: currentPost.authorId,
          userName: currentPost.authorName,
          avatarUrl: currentPost.authorAvatar,
          showFollowButton: !currentPost.isFollowing,
          isFollowing: currentPost.isFollowing,
          onFollowTap: () {
            widget.onFollowTap(); // Appelle le Provider
            
          },
        ),

        if (currentPost.isFollowing) ...[
          const SizedBox(height: 6),
          const ActionIcon(icon: Icons.send),
        ],

        const SizedBox(height: 14),

        ActionIcon(
          icon: currentPost.isLiked ? Icons.favorite : Icons.favorite_border,
          color: currentPost.isLiked ? Colors.pinkAccent : Colors.white,
          label: currentPost.likesCount.toString(),
          onTap: () {
            widget.onLikeTap(); // Appelle le Provider
            // ❌ PLUS BESOIN DE setState(() {}) ! Riverpod gère le rebuild
          },
        ),

        ActionIconCommentaire(
          icon: Icons.chat_bubble_outline,
          label: currentPost.commentsCount.toString(),
          onOpenComments: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CommentsSheet(
                postId: currentPost.id,
                currentUserId: widget.currentUserId ?? 0,
                postUserId: currentPost.authorId,
              ),
            );
          },
        ),

        const ActionIconSetting(icon: Icons.more_vert),

        const SizedBox(height: 14),

        // 🎵 Disque musical
        RotationTransition(
          turns: _musicDiscController,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [Colors.black, Colors.grey.shade800, Colors.black],
              ),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}