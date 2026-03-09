// losivio/lib/widgets/homes_page_widget.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../services/post_service.dart';
import '../models/commentsSheet.dart';
import '../models/ActionIconSetting.dart';
import '../models/ActionIcon.dart';
import '../models/post_model.dart';
import '../models/media_model.dart';
import '../screens/LiveSpectateurPage.dart';
import '../widgets/utilsWidget.dart';
import '../models/user.dart';

const int _pageSize = 5;

/* -------------------------------------------------------------------------- */
/*                               DESIGN TOKENS                                */
/* -------------------------------------------------------------------------- */

const LinearGradient kDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF0F172A), // slate-900
    Color(0xFF111827), // gray-900
    Color(0xFF1E293B), // slate-800
  ],
);

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFEC4899), // pink-500
    Color(0xFFA855F7), // purple-500
    Color(0xFF22D3EE), // cyan-400
  ],
);

enum HomeTab {
  live,
  stim,
  forYou,
  following,
  explore,
}
/* -------------------------------------------------------------------------- */
/*                                   HOME                                     */
/* -------------------------------------------------------------------------- */

class HomeWidget extends ConsumerStatefulWidget {
  const HomeWidget({super.key});

  @override
  ConsumerState<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends ConsumerState<HomeWidget> {

  final PageController _pageController = PageController();

  List<PostModel> posts = [];

  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _currentVerticalIndex = 0;
  bool _lockVerticalScroll = false;
  HomeTab _activeTab = HomeTab.stim;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPostsInitial());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPostsInitial() async {
    setState(() {
      _loadingInitial = true;
      _loadingMore = false;
      _hasMore = true;
      _currentPage = 1;
      posts.clear();
    });

    final user = ref.read(userProvider).value;

    // On appelle le service même si user est nul.
    // L'opérateur ?.id renverra null si l'utilisateur n'est pas connecté.
    final data = await PostService.getPosts(
      userId: user?.id, 
      page: 1,
      limit: _pageSize,
    );

    if (mounted) {
      setState(() {
        posts = data;
        _loadingInitial = false;
        _hasMore = data.length == _pageSize;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);

    try {
      final user = ref.read(userProvider).value;

      final nextPage = _currentPage + 1;
      debugPrint('Chargement page $nextPage pour userId: ${user?.id}');

      final data = await PostService.getPosts(
        userId: user?.id, // Utilise ?.id au lieu de .id
        page: nextPage,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (data.isNotEmpty) {
            posts.addAll(data);
            _currentPage = nextPage;
          }
          _hasMore = data.length == _pageSize;
        });
      }
    } catch (e) {
      debugPrint('Erreur de chargement: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _handleToggleLike(int index) async {
    final currentUser = ref.read(userProvider).value;
    if (currentUser == null) return;

    final post = posts[index];
    final bool oldStatus = post.isLiked;
    final int oldLikesCount = post.likesCount;

    // --- 1. MISE À JOUR OPTIMISTE ---
    setState(() {
      posts[index] = post.copyWith(
        isLiked: !oldStatus,
        likesCount: oldStatus ? oldLikesCount - 1 : oldLikesCount + 1,
      );
    });

    // --- 2. APPEL API ---
    // On suppose que PostService.toggleLike existe sur le même modèle que toggleFollow
    final success = await PostService.toggleLike(
      postId: post.id,
      userId: currentUser.id,
      postUserId : post.authorId,
    );

    // --- 3. ROLLBACK SI ERREUR ---
    if (!success && mounted) {
      setState(() {
        posts[index] = post.copyWith(
          isLiked: oldStatus,
          likesCount: oldLikesCount,
        );
      });
    }
  }

  Future<void> _handleToggleFollow(int index) async {
    final currentUser = ref.read(userProvider).value;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connectez-vous pour suivre ce créateur")),
      );
      return;
    }

    final post = posts[index];
    final bool oldStatus = post.isFollowing;

    // --- 1. MISE À JOUR OPTIMISTE ---
    setState(() {
      posts[index] = post.copyWith(isFollowing: !oldStatus);
    });

    // --- 2. APPEL API ---
    final success = await PostService.toggleFollow(
      currentUserId: currentUser.id,
      targetUserId: post.authorId,
    );

    // --- 3. ROLLBACK SI ERREUR ---
    if (!success && mounted) {
      setState(() {
        posts[index] = post.copyWith(isFollowing: oldStatus);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la mise à jour")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.value;
    return Stack(
      children: [
        /// 🔥 CONTENU (Live ou Feed)
        Positioned.fill(
          child: _buildBody(user),
        ),

        /// 🔥 HEADER TOUJOURS PRÉSENT
        HeaderWidget(
          activeTab: _activeTab,
          onTabChanged: (tab) {
            if (_activeTab == tab) return;

            setState(() => _activeTab = tab);

            if (tab != HomeTab.live) {
              _loadPostsInitial();
            }
          },
        ),
      ],
    );
  }

  Widget _buildBody(User? user) {
    switch (_activeTab) {
      case HomeTab.live:
        return const LiveSpectateurPage(
          channelName: 'test_room',
        );

      case HomeTab.stim:
      case HomeTab.forYou:
      case HomeTab.following:
      case HomeTab.explore:
      default:
        return _buildFeed(user);
    }
  }

  Widget _buildFeed(User? user) {
    if (_loadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    return PageView.builder(
      key: const PageStorageKey('home_feed'),
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: _lockVerticalScroll
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(parent: PageScrollPhysics()),
      itemCount: posts.length + (_hasMore ? 1 : 0),
      onPageChanged: (index) {
        setState(() => _currentVerticalIndex = index);

        if (!_loadingMore && _hasMore && index >= posts.length - 2) {
          _loadMorePosts();
        }
      },

      itemBuilder: (_, index) {
        if (index >= posts.length) return const LoadingIndicator();

        return _PostItem(
          post: posts[index],
          currentUserId: user?.id,
          isVisible: index == _currentVerticalIndex,
          onLockVerticalScroll: (lock) => setState(() => _lockVerticalScroll = lock),
          onToggleFollow: () => _handleToggleFollow(index), // Ta fonction follow existante
          onDoubleTapLike: () => _handleToggleLike(index), // Appelle ta nouvelle fonction Like
        );
      },
    );
  }

}

/* -------------------------------------------------------------------------- */
/*                                POST ITEM                                   */
/* -------------------------------------------------------------------------- */

class _PostItem extends StatefulWidget { // Changé en StatefulWidget
  final PostModel post;
  final int? currentUserId;
  final bool isVisible;
  final ValueChanged<bool> onLockVerticalScroll;
  final VoidCallback onToggleFollow;
  final VoidCallback onDoubleTapLike;

  const _PostItem({
    required this.post,
    this.currentUserId,
    required this.isVisible,
    required this.onLockVerticalScroll,
    required this.onToggleFollow,
    required this.onDoubleTapLike,
  });

  @override
  State<_PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<_PostItem> {
  bool _showHeart = false; // Pour afficher/masquer l'animation

  @override
  Widget build(BuildContext context) {
    final medias = widget.post.medias;

    return GestureDetector(
      onDoubleTap: () {
        setState(() => _showHeart = true);
        widget.onDoubleTapLike(); // Appelle la logique de Like
      },
      child: Stack(
        children: [
          // 1. Média
          Positioned.fill(
            child: _MediaCarousel(
              medias: medias,
              isPostVisible: widget.isVisible,
              onHorizontalDragStart: () => widget.onLockVerticalScroll(true),
              onHorizontalDragEnd: () => widget.onLockVerticalScroll(false),
            ),
          ),

          // 2. Gradient Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Animation du Coeur (si activée)
          if (_showHeart)
            HeartOverlay(onFinished: () => setState(() => _showHeart = false)),

          // 4. Textes
          _BottomLeftText(
            title: medias.isNotEmpty ? medias.first.title ?? '' : '',
            author: widget.post.authorName,
          ),

          // 5. Actions
          _RightActionsColumn(post: widget.post, currentUserId: widget.currentUserId, onRefresh: widget.onToggleFollow, onLikeTap: widget.onDoubleTapLike,),
        ],
      ),
    );
  }
}
/* -------------------------------------------------------------------------- */
/*                              MEDIA CAROUSEL                                */
/* -------------------------------------------------------------------------- */

class _MediaCarousel extends StatefulWidget {
  final List<MediaModel> medias;
  final bool isPostVisible;
  final VoidCallback onHorizontalDragStart;
  final VoidCallback onHorizontalDragEnd;

  const _MediaCarousel({
    required this.medias,
    required this.isPostVisible,
    required this.onHorizontalDragStart,
    required this.onHorizontalDragEnd,
  });

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.medias.isEmpty) {
      return Container(
        decoration: const BoxDecoration(gradient: kDarkGradient),
      );
    }

    if (widget.medias.length == 1) {
      return _buildMedia(widget.medias.first, widget.isPostVisible);
    }

    return GestureDetector(
      onHorizontalDragStart: (_) => widget.onHorizontalDragStart(),
      onHorizontalDragEnd: (_) => widget.onHorizontalDragEnd(),
      onHorizontalDragCancel: widget.onHorizontalDragEnd,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.medias.length,
            onPageChanged: (index) {
              if (_currentIndex != index) {
                setState(() => _currentIndex = index);
              }
            },
            itemBuilder: (_, i) {
              final media = widget.medias[i];
              final shouldPlay = widget.isPostVisible && i == _currentIndex;
              return _buildMedia(media, shouldPlay);
            },
          ),
          DotsIndicator(count: widget.medias.length, index: _currentIndex),
        ],
      ),
    );
  }

  Widget _buildMedia(MediaModel media, bool shouldPlay) {
    final String url = media.url;

    debugPrint("🔗 MEDIA FINAL URL: $url");

    if (media.mediaType == 'image') {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, __, error) {
          debugPrint("❌ Image error: $error");
          return const Icon(Icons.broken_image, color: Colors.white);
        },
      );
    }

    return VideoPlayerFullScreen(videoUrl: url, shouldPlay: shouldPlay);
  }

}

/* -------------------------------------------------------------------------- */
/*                               VIDEO PLAYER                                 */
/* -------------------------------------------------------------------------- */

class VideoPlayerFullScreen extends StatefulWidget {
  final String videoUrl;
  final bool shouldPlay;

  const VideoPlayerFullScreen({
    super.key,
    required this.videoUrl,
    required this.shouldPlay,
  });

  @override
  State<VideoPlayerFullScreen> createState() => _VideoPlayerFullScreenState();
}

class _VideoPlayerFullScreenState extends State<VideoPlayerFullScreen> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _manuallyPaused = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _updatePlayback();
      });
    _controller.setLooping(true);
  }

  @override
  void didUpdateWidget(VideoPlayerFullScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldPlay && !_controller.value.isPlaying && !_manuallyPaused) {
      _controller.play();
    } else if (!widget.shouldPlay && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  void _updatePlayback() {
    if (!_initialized) return;
    if (widget.shouldPlay && !_manuallyPaused) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _manuallyPaused = true;
            _controller.pause();
          } else {
            _manuallyPaused = false;
            _controller.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

          if (!_controller.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: kAccentGradient,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                UI PARTS                                    */
/* -------------------------------------------------------------------------- */
class _BottomLeftText extends StatelessWidget {
  final String title;
  final String author;

  const _BottomLeftText({
    required this.title,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 28,
      right: 100,
      child: PostTextWidget(
        title: title,
        author: author,
      ),
    );
  }
}


class _RightActionsColumn extends StatelessWidget {
  final PostModel post;
  final int? currentUserId;
  final VoidCallback? onRefresh;
  final VoidCallback? onLikeTap;

  const _RightActionsColumn({required this.post, this.currentUserId,this.onRefresh, this.onLikeTap,});

  @override
  Widget build(BuildContext context) {

    return Positioned(
      right: 12,
      bottom: 20,
      child: Column(
        children: [
          // --- 
          //
          // + BOUTON SUIVRE ---
          Avatar(
            userId: post.authorId, // 🔹 Passez l'ID de l'auteur
            userName: post.authorName,
            avatarUrl: post.authorAvatar,
            showFollowButton: !post.isFollowing, 
            isFollowing: post.isFollowing,
            onFollowTap: onRefresh
          ),
          
          // --- BOUTON MESSAGE (Si déjà suivi) ---
          if (post.isFollowing) ...[
            const SizedBox(height: 6),
            GestureDetector( // On utilise GestureDetector pour pallier l'absence d'onTap dans ActionIcon
              onTap: () {
                debugPrint("Ouvrir la messagerie avec ${post.authorName}");
              },
              child: const ActionIcon(
                icon: Icons.send, 
                //label: 'Message',
              ),
            ),
          ],

          const SizedBox(height: 14),

          // --- LIKES ---
          ActionIcon(
            icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
            label: post.likesCount.toString(),
              onTap:onLikeTap,
          ),

          // --- COMMENTAIRES ---
          ActionIconCommentaire(
            icon: Icons.chat_bubble_outline,
            label: post.commentsCount.toString(),
            onOpenComments: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CommentsSheet(postId: post.id, currentUserId: currentUserId ?? 0, postUserId: post.authorId,),
              );
            },
          ),

          //const ActionIcon(icon: Icons.share, label: 'Share'),
          const ActionIconSetting(icon: Icons.more_vert),
        ],
      ),
    );
  }
}

// Créer le Header, à gauche en haut une icone de "ive" , en haut à droite une icone de 'recherche' (ces deux icones sont fixes). Au centre en haut, une navigation entre "stm", "Pour toi" , "suivis", "explorer " (similaire à TikTok).
class _HeaderTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _HeaderTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: Colors.white, width: 2),
                )
              : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: isActive ? 18 : 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class HeaderWidget extends StatelessWidget {
  final HomeTab activeTab;
  final ValueChanged<HomeTab> onTabChanged;

  const HeaderWidget({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 30,
      left: 10,
      right: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              debugPrint('LIVE cliqué');
              onTabChanged(HomeTab.live);
            },
            child: const Icon(
              Icons.live_tv,
              color: Colors.white,
              size: 28,
            ),
          ),

          /// 🔥 Onglets centraux
          Row(
            children: [
              _HeaderTab(
                label: 'STM',
                isActive: activeTab == HomeTab.stim,
                onTap: () => onTabChanged(HomeTab.stim),
              ),
              _HeaderTab(
                label: 'Pour toi',
                isActive: activeTab == HomeTab.forYou,
                onTap: () => onTabChanged(HomeTab.forYou),
              ),
              _HeaderTab(
                label: 'Suivis',
                isActive: activeTab == HomeTab.following,
                onTap: () => onTabChanged(HomeTab.following),
              ),
              _HeaderTab(
                label: 'Explorer',
                isActive: activeTab == HomeTab.explore,
                onTap: () => onTabChanged(HomeTab.explore),
              ),
            ],
          ),

          const Icon(Icons.search, color: Colors.white, size: 28),
        ],
      ),
    );
  }
}

// class PostTextWidget pour afficher le texte en bas à gauche d'un post (titre + auteur). si le texte est trop long, il doit être tronqué avec des points de suspension(puis le deplier ou le plier au clic).
class PostTextWidget extends StatefulWidget {
  final String title;
  final String author;

  const PostTextWidget({
    super.key,
    required this.title,
    required this.author,
  });

  @override
  State<PostTextWidget> createState() => _PostTextWidgetState();
}

class _PostTextWidgetState extends State<PostTextWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@${widget.author}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.title,
            maxLines: _isExpanded ? 10 : 2, // Augmente les lignes si déplié
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
        ],
      ),
    );
  }
}

class HeartOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  const HeartOverlay({super.key, required this.onFinished});

  @override
  State<HeartOverlay> createState() => _HeartOverlayState();
}

class _HeartOverlayState extends State<HeartOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center( // Ajoute un Center pour que le coeur soit au milieu
      child: ScaleTransition(
        scale: _scale,
        child: const Icon(Icons.favorite, color: Colors.white, size: 100),
      ),
    );
  }
}