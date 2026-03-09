// losivio/lib/widgets/homes_page_widget.dart

import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/user_provider.dart'; // contient les préférences de traduction et sous-titres
import '../providers/posts_provider.dart';
import '../models/commentsSheet.dart';
import '../models/ActionIconSetting.dart';
import '../models/ActionIcon.dart';
import '../models/post_model.dart';
import '../models/media_model.dart';
import '../screens/LiveSpectateurPage.dart';
import '../widgets/utilsWidget.dart';
import '../models/user.dart';

/* -------------------------------------------------------------------------- */
/* DESIGN TOKENS                                                              */
/* -------------------------------------------------------------------------- */

const LinearGradient kDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFF1E293B)],
);

enum HomeTab { live, STIM, FORYOU, FOLLOWING, EXPLORE }

/* -------------------------------------------------------------------------- */
/* HOME                                                                      */
/* -------------------------------------------------------------------------- */

class HomeWidget extends ConsumerStatefulWidget {
  const HomeWidget({super.key});

  @override
  ConsumerState<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends ConsumerState<HomeWidget> {
  final PageController _pageController = PageController();
  int _currentVerticalIndex = 0;
  bool _lockVerticalScroll = false;
  HomeTab _activeTab = HomeTab.STIM;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider).value;
      // 🔥 AJOUT DE L'ARGUMENT tab ICI :
      ref
          .read(postsProvider.notifier)
          .loadInitialPosts(user?.id, tab: _activeTab.name);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _pageController.dispose();
    super.dispose();
  }

  void _handleTabChange(HomeTab tab) {
    setState(() {
      _activeTab = tab;
      _currentVerticalIndex = 0; // 🔥 FIX 1 : On remet l'index à 0
    });

    // 🔥 FIX 2 : On ramène le PageController tout en haut
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    WakelockPlus.enable();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).value;

    return Stack(
      children: [
        Positioned.fill(child: _buildBody(user)),

        HeaderWidget(
          activeTab: _activeTab,
          onTabChanged: (tab) {
            final userId = ref.read(userProvider).value?.id;

            if (tab == _activeTab) {
              // 🔄 L'utilisateur clique sur l'onglet ACTUEL
              if (tab != HomeTab.live) {
                // 1. On s'assure d'être à l'index 0 visuellement
                if (_pageController.hasClients && _currentVerticalIndex != 0) {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }

                // 2. On reset l'index interne
                setState(() => _currentVerticalIndex = 0);

                // 3. ON FORCE LE RECHARGEMENT (Même si on est déjà à 0)
                // Cela va déclencher le CircularProgressIndicator si ton provider
                // passe 'isLoadingInitial' à true.
                ref
                    .read(postsProvider.notifier)
                    .loadInitialPosts(userId, tab: tab.name);
              }
            } else {
              // 🔀 Changement d'onglet classique
              _handleTabChange(tab);
              if (tab != HomeTab.live) {
                ref
                    .read(postsProvider.notifier)
                    .loadInitialPosts(userId, tab: tab.name);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildBody(User? user) {
    if (_activeTab == HomeTab.live) {
      return const LiveSpectateurPage(channelName: 'test_room');
    }
    return _buildFeed(user);
  }

  Widget _buildFeed(User? user) {
    final postsState = ref.watch(postsProvider);

    if (postsState.isLoadingInitial) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      pageSnapping: true,
      padEnds: false,
      physics:
          _lockVerticalScroll
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
      itemCount: postsState.posts.length + (postsState.hasMore ? 1 : 0),
      onPageChanged: (index) {
        setState(() => _currentVerticalIndex = index);

        if (index >= postsState.posts.length - 2) {
          ref.read(postsProvider.notifier).loadMorePosts(user?.id);
        }

        // 🔥 Précharge prochaine vidéo
        // 🔥 Précharge prochaine vidéo (CORRIGÉ)
        if (index + 1 < postsState.posts.length) {
          final nextPost = postsState.posts[index + 1];
          for (final media in nextPost.medias) {
            if (media.mediaType == 'video') {
              DefaultCacheManager().getFileFromCache(media.url).then((
                fileInfo,
              ) {
                if (fileInfo == null) {
                  // Le fichier n'est pas en cache, on lance le téléchargement
                  DefaultCacheManager().downloadFile(media.url);
                }
              });
            }
          }
        }
      },
      itemBuilder: (_, index) {
        if (index >= postsState.posts.length) return const LoadingIndicator();
        final post = postsState.posts[index];

        return _PostItem(
          key: ValueKey('post_${post.id}'),
          post: post,
          currentUserId: user?.id,
          isVisible: index == _currentVerticalIndex,
          onLockVerticalScroll:
              (lock) => setState(() => _lockVerticalScroll = lock),
          onToggleFollow:
              () => ref
                  .read(postsProvider.notifier)
                  .toggleFollow(post.authorId, user!.id),
          onDoubleTapLike:
              () => ref
                  .read(postsProvider.notifier)
                  .toggleLike(post.id, user!.id, post.authorId),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* POST ITEM                                                                  */
/* -------------------------------------------------------------------------- */

class _PostItem extends ConsumerStatefulWidget {
  final PostModel post;
  final int? currentUserId;
  final bool isVisible;
  final ValueChanged<bool> onLockVerticalScroll;
  final VoidCallback onToggleFollow;
  final VoidCallback onDoubleTapLike;

  const _PostItem({
    super.key,
    required this.post,
    this.currentUserId,
    required this.isVisible,
    required this.onLockVerticalScroll,
    required this.onToggleFollow,
    required this.onDoubleTapLike,
  });

  @override
  ConsumerState<_PostItem> createState() => _PostItemState();
}

class _PostItemState extends ConsumerState<_PostItem> {
  bool _showHeart = false;
  //bool _viewCounted = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        setState(() => _showHeart = true);
        widget.onDoubleTapLike();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: _MediaCarousel(
              medias: widget.post.medias,
              isPostVisible: widget.isVisible,
              onHorizontalDragStart: () => widget.onLockVerticalScroll(true),
              onHorizontalDragEnd: () => widget.onLockVerticalScroll(false),

              // 🔥 ICI on reçoit la vue détectée
              onViewDetected: (mediaId, watchTime) {
                if (widget.currentUserId == null) return;

                ref
                    .read(postsProvider.notifier)
                    .registerView(
                      postId: widget.post.id,
                      mediaId: mediaId,
                      watchTime: watchTime,
                      userId: widget.currentUserId!,
                    );
              },
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_showHeart)
            HeartOverlay(onFinished: () => setState(() => _showHeart = false)),

          _BottomLeftText(
            title:
                widget.post.medias.isNotEmpty
                    ? widget.post.medias.first.title ?? ''
                    : '',
            author: widget.post.authorName,
          ),

          Positioned(
            right: 12,
            bottom: 20,
            child: _RightActionsColumn(
              post: widget.post,
              currentUserId: widget.currentUserId,
              onFollowTap: widget.onToggleFollow,
              onLikeTap: widget.onDoubleTapLike,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* MEDIA CAROUSEL                                                               */
/* -------------------------------------------------------------------------- */

class _MediaCarousel extends ConsumerStatefulWidget {
  final List<MediaModel> medias;
  final bool isPostVisible;
  final VoidCallback onHorizontalDragStart;
  final VoidCallback onHorizontalDragEnd;
  //final ValueChanged<bool>? onVideoPlayingChanged;
  final void Function(int mediaId, int watchTime)? onViewDetected;

  const _MediaCarousel({
    required this.medias,
    required this.isPostVisible,
    required this.onHorizontalDragStart,
    required this.onHorizontalDragEnd,
    //required this.onVideoPlayingChanged,
    this.onViewDetected,
  });

  @override
  ConsumerState<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends ConsumerState<_MediaCarousel> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.medias.isEmpty)
      return Container(
        decoration: const BoxDecoration(gradient: kDarkGradient),
      );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          widget.onHorizontalDragStart();
        }
        if (notification is ScrollEndNotification) {
          widget.onHorizontalDragEnd();
        }
        return false;
      },
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.medias.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (_, i) {
          final media = widget.medias[i];
          final shouldPlay = widget.isPostVisible && i == _currentIndex;

          if (media.mediaType == 'video') {
            final userPrefs = ref.watch(userProvider).value;
            // On détermine si on doit utiliser la version traduite
            // 2. Vérifier si on bascule sur la traduction
            // Note: On vérifie .videoUrlTranslate car c'est la vidéo mixée
            final bool useTranslated = userPrefs?.translatePost == true && 
                                      media.videoUrlTranslate != null;

            final String finalVideoUrl = useTranslated ? media.videoUrlTranslate! : media.url;
            debugPrint(
              "URL traduite de la vidéo : ${media.translatedAudioUrl}",
            );
            debugPrint("id traduite de la vidéo : ${media.id}");
            debugPrint("URL traduite de la vidéo : ${media.videoUrlTranslate}");
            debugPrint("Dois-je jouer la vidéo traduite ? : $useTranslated",
            ); // Vérifie si l'utilisateur préfère les vidéos traduites et si une traduction est disponible

            
            return Stack(
              fit: StackFit.expand,
              children: [
                if (media.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: media.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white24,
                          ),
                        ),
                    errorWidget:
                        (context, url, error) =>
                            const Icon(Icons.error, color: Colors.white24),
                  ),

                if (media.mediaType == 'video')
                  VideoPlayerFullScreen(
                    videoUrl: finalVideoUrl,
                    translatedAudioUrl: media.translatedAudioUrl,
                    shouldPlay: shouldPlay,
                    onPlayingChanged: null,
                    onViewThresholdReached: (watchTime) {
                      widget.onViewDetected?.call(media.id, watchTime);
                    },
                  )
                else
                  CachedNetworkImage(imageUrl: media.url, fit: BoxFit.cover),
              ],
            );
          } else {
            return CachedNetworkImage(imageUrl: media.url, fit: BoxFit.cover);
          }
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* VIDEO PLAYER                                                                 */
/* -------------------------------------------------------------------------- */

class VideoPlayerFullScreen extends StatefulWidget {
  final String videoUrl;
  final bool shouldPlay;
  final String? translatedAudioUrl;
  final ValueChanged<bool>? onPlayingChanged;
  final void Function(int watchTime)? onViewThresholdReached;

  const VideoPlayerFullScreen({
    super.key,
    required this.videoUrl,
    this.translatedAudioUrl,
    required this.shouldPlay,
    required this.onPlayingChanged,
    this.onViewThresholdReached,
  });

  @override
  State<VideoPlayerFullScreen> createState() => _VideoPlayerFullScreenState();
}

class _VideoPlayerFullScreenState extends State<VideoPlayerFullScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  AudioPlayer? _audioPlayer;
  bool _initialized = false;
  bool _isTranslated = false;
  bool _manuallyPaused = false;
  bool _viewSent = false;
  bool _hasError = false;
  int _startWatchSecond = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.shouldPlay) {
      _initVideo();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.pause();
    }
  }

  // --- NOUVEAU : Fonction de listener extraite pour être supprimable ---
  void _videoListener() {
    if (_controller == null || !mounted || !_initialized) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (position >= duration && !_viewSent) {
      _viewSent = true;
      final watchTime = duration.inSeconds - _startWatchSecond;
      if (watchTime >= 3) {
        widget.onViewThresholdReached?.call(watchTime);
      }
    }
  }

  Future<void> _initVideo() async {
    if (_initialized || !mounted) return;

    if (widget.videoUrl.contains('iframe.mediadelivery.net')) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      if (mounted) setState(() => _hasError = false);

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(false);
      controller.addListener(_videoListener); // On attache le listener

      setState(() {
        _controller = controller;
        _initialized = true;
      });

      _updatePlayback();
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _updatePlayback() {
    if (!_initialized || _controller == null) return;

    if (widget.shouldPlay && !_manuallyPaused) {
      if (!_controller!.value.isPlaying) {
        _startWatchSecond = _controller!.value.position.inSeconds;
        _controller!.play();
        widget.onPlayingChanged?.call(true);
      }
    } else {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        widget.onPlayingChanged?.call(false);
      }
    }
  }

  @override
  void didUpdateWidget(VideoPlayerFullScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Tu devrais aussi vérifier si 'videoUrl' a changé !
    if (oldWidget.videoUrl != widget.videoUrl) {
      _viewSent = false;
      _initialized = false;
      _controller?.removeListener(_videoListener);
      _controller?.dispose();
      _controller = null;
      _initVideo();
      return; // On sort pour éviter de doubler les appels
    }
    // Si devient visible → init
    if (widget.shouldPlay && !_initialized) {
      _initVideo();
    }

    // Si devient invisible → calcul réel
    if (!widget.shouldPlay && oldWidget.shouldPlay && !_viewSent) {
      final endSecond = _controller?.value.position.inSeconds ?? 0;
      final watchTime = endSecond - _startWatchSecond;

      if (watchTime >= 3) {
        widget.onViewThresholdReached?.call(watchTime);
      }

      _viewSent = true;
    }

    if (_initialized) {
      _updatePlayback();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 🛡️ CRUCIAL : Retirer le listener AVANT de dispose le controller
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _handleTap() {
    if (_controller == null || !_initialized || !mounted) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _manuallyPaused = true;
        widget.onPlayingChanged?.call(false);
      } else {
        _controller!.play();
        _manuallyPaused = false;
        widget.onPlayingChanged?.call(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si une erreur survient, on affiche un bouton de retry ou une icône
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white54, size: 50),
            const SizedBox(height: 10),
            const Text(
              "Erreur de connexion",
              style: TextStyle(color: Colors.white),
            ),
            TextButton(
              onPressed: () {
                _initVideo(); // On tente de recharger
              },
              child: const Text("Réessayer"),
            ),
          ],
        ),
      );
    }

    if (!_initialized || _controller == null) return const SizedBox();

    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          if (!_controller!.value.isPlaying)
            const CircleAvatar(
              backgroundColor: Colors.black26,
              child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
            ),
          // 🛡️ PROTECTION : On n'affiche l'indicateur que si monté et non nul
          if (mounted && _controller != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: const Color(0xFFEC4899).withOpacity(0.8),
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* UI PARTS                                    */
/* -------------------------------------------------------------------------- */
class _BottomLeftText extends StatelessWidget {
  final String title;
  final String author;

  const _BottomLeftText({required this.title, required this.author});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 28,
      right: 100,
      child: PostTextWidget(title: title, author: author),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* RIGHT ACTIONS COLUMN                                           */
/* -------------------------------------------------------------------------- */
class _RightActionsColumn extends StatefulWidget {
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
  State<_RightActionsColumn> createState() => _RightActionsColumnState();
}

class _RightActionsColumnState extends State<_RightActionsColumn>
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
    final post = widget.post;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Avatar(
          key: ValueKey('avatar_${post.authorId}_${post.authorAvatar}'),
          userId: post.authorId,
          userName: post.authorName,
          avatarUrl: post.authorAvatar,
          showFollowButton: !post.isFollowing,
          isFollowing: post.isFollowing,
          onFollowTap: widget.onFollowTap,
        ),

        if (post.isFollowing) ...[
          const SizedBox(height: 6),
          const ActionIcon(icon: Icons.send),
        ],

        const SizedBox(height: 14),

        ActionIcon(
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          color: post.isLiked ? Colors.pinkAccent : Colors.white,
          label: post.likesCount.toString(),
          onTap: widget.onLikeTap,
        ),

        ActionIconCommentaire(
          icon: Icons.chat_bubble_outline,
          label: post.commentsCount.toString(),
          onOpenComments: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled:
                  true, // INDISPENSABLE pour le DraggableScrollableSheet
              backgroundColor:
                  Colors.transparent, // Permet de voir l'arrondi et l'ombre
              barrierColor:
                  Colors.black54, // Assombrit légèrement l'arrière-plan du post
              builder:
                  (context) => CommentsSheet(
                    postId: post.id,
                    // Si currentUserId est null, on passe null (le widget gérera l'état "non-connecté")
                    currentUserId: widget.currentUserId,
                    postUserId: post.authorId,
                  ),
            );
          },
        ),

        const ActionIconSetting(icon: Icons.more_vert),

        const SizedBox(height: 14),

        // 🎵 Disque musical animé style TikTok
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
          border:
              isActive
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
            onTap: () => onTabChanged(HomeTab.live),
            child: const Icon(Icons.live_tv, color: Colors.white, size: 28),
          ),
          Row(
            children: [
              _HeaderTab(
                label: 'STIM',
                isActive: activeTab == HomeTab.STIM,
                onTap: () => onTabChanged(HomeTab.STIM),
              ),
              _HeaderTab(
                label: 'Pour toi',
                isActive: activeTab == HomeTab.FORYOU,
                onTap: () => onTabChanged(HomeTab.FORYOU),
              ),
              _HeaderTab(
                label: 'Suivis',
                isActive: activeTab == HomeTab.FOLLOWING,
                onTap: () => onTabChanged(HomeTab.FOLLOWING),
              ),
              _HeaderTab(
                label: 'Explorer',
                isActive: activeTab == HomeTab.EXPLORE,
                onTap: () => onTabChanged(HomeTab.EXPLORE),
              ),
            ],
          ),
          const Icon(Icons.search, color: Colors.white, size: 28),
        ],
      ),
    );
  }
}

class PostTextWidget extends StatefulWidget {
  final String title;
  final String author;

  const PostTextWidget({super.key, required this.title, required this.author});

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
            maxLines: _isExpanded ? 10 : 2,
            overflow:
                _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
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

class _HeartOverlayState extends State<HeartOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
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
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: const Icon(Icons.favorite, color: Colors.white, size: 100),
      ),
    );
  }
}
