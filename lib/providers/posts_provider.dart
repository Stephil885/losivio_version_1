// lib/providers/posts_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

// 1. L'état de notre écran (State)
class PostsState {
  final List<PostModel> posts;
  final String currentTab;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const PostsState({
    this.posts = const [],
    this.currentTab = 'STIM',
    this.isLoadingInitial = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  PostsState copyWith({
    List<PostModel>? posts,
    String? currentTab,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      currentTab: currentTab ?? this.currentTab,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
    );
  }
}

// 2. Le Notifier (Logique métier)
class PostsNotifier extends StateNotifier<PostsState> {
  PostsNotifier() : super(const PostsState());
  final Set<String> _sentViews = {};
  final int _limit = 4; // Taille de page

  // Charger les posts initiaux
  Future<void> loadInitialPosts(int? userId, {required String tab}) async {
    final isNewTab = state.currentTab != tab;

    // Si on a déjà des posts ET qu'on n'a pas changé d'onglet, on garde le cache
    if (!isNewTab && state.posts.isNotEmpty) return; 

    try {
      // Si on change d'onglet, on vide l'ancienne liste instantanément pour l'UX
      state = state.copyWith(
        isLoadingInitial: true, 
        error: null,
        posts: isNewTab ? [] : state.posts,
        currentTab: tab, // On enregistre le nouvel onglet
      );
      
      final newPosts = await PostService.getPosts(
        userId: userId,
        tab: tab, // 🔥 On passe le tab à l'API
        page: 1,
        limit: _limit,
      );

      state = state.copyWith(
        posts: newPosts,
        isLoadingInitial: false,
        hasMore: newPosts.length == _limit,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoadingInitial: false, error: e.toString());
    }
  }

  // Charger plus de posts
  Future<void> loadMorePosts(int? userId) async {
    if (state.isLoadingMore || !state.hasMore) return;

    try {
      state = state.copyWith(isLoadingMore: true);
      final nextPage = state.page + 1;

      final newPosts = await PostService.getPosts(
        userId: userId,
        tab: state.currentTab, // 🔥 On réutilise l'onglet mémorisé
        page: nextPage,
        limit: _limit,
      );

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoadingMore: false,
        hasMore: newPosts.length == _limit,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  // Action: Toggle Like
  Future<void> toggleLike(int postId, int currentUserId, int postAuthorId) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = state.posts[index];
    final oldStatus = post.isLiked;
    final oldCount = post.likesCount;

    // 1. Optimistic Update (Mise à jour immédiate de l'UI)
    final updatedPost = post.copyWith(
      isLiked: !oldStatus,
      likesCount: oldStatus ? oldCount - 1 : oldCount + 1,
    );
    
    // On met à jour la liste sans tout recharger
    List<PostModel> updatedList = List.from(state.posts);
    updatedList[index] = updatedPost;
    state = state.copyWith(posts: updatedList);

    // 2. Appel API
    final success = await PostService.toggleLike(
      postId: postId,
      userId: currentUserId,
      postUserId: postAuthorId,
    );

    // 3. Rollback si erreur
    if (!success) {
      updatedList[index] = post; // Remet l'original
      state = state.copyWith(posts: updatedList);
    }
  }

  // Action: Toggle Follow
  Future<void> toggleFollow(int authorId, int currentUserId) async {
    // Note: Cela peut affecter plusieurs posts du même auteur
    final updatedList = state.posts.map((post) {
      if (post.authorId == authorId) {
        return post.copyWith(isFollowing: !post.isFollowing);
      }
      return post;
    }).toList();

    // Sauvegarde pour rollback
    final oldList = state.posts;

    // 1. Optimistic Update
    state = state.copyWith(posts: updatedList);

    // 2. Appel API
    final success = await PostService.toggleFollow(
      currentUserId: currentUserId,
      targetUserId: authorId,
    );

    // 3. Rollback
    if (!success) {
      state = state.copyWith(posts: oldList);
    }
  }

  Future<void> registerView({
    required int postId,
    required int mediaId,
    required int watchTime,
    required int userId,
  }) async {

    final key = "${postId}_$mediaId";

    // 🚫 Empêche double envoi
    if (_sentViews.contains(key)) return;

    final success = await PostService.registerView(
      postId: postId,
      mediaId: mediaId,
      watchTime: watchTime,
      userId: userId,
    );

    if (!success) return;

    _sentViews.add(key);

    state = state.copyWith(
      posts: state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            viewsCount: post.viewsCount + 1,
          );
        }
        return post;
      }).toList(),
    );
  }
}

// 3. Le Provider global
final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  return PostsNotifier();
});