// lib/screens/discover_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/discover_widget.dart';
import '../providers/posts_provider.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // On charge initialement si la liste est vide
      if (ref.read(postsProvider).posts.isEmpty) {
        ref.read(postsProvider.notifier).loadInitialPosts(null, tab: 'TOUT');
      }
    });
  }

  bool _onScrollNotification(ScrollNotification scrollInfo) {
    final state = ref.read(postsProvider);

    if (state.isLoadingMore || state.isLoadingInitial) return false;

    if (!scrollInfo.metrics.outOfRange &&
        scrollInfo.metrics.pixels >
            scrollInfo.metrics.maxScrollExtent - 500) {
      ref.read(postsProvider.notifier).loadMorePosts(null);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(postsProvider.notifier)
                .loadInitialPosts(null, tab: state.currentTab);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              const ModernHeader(),
              const CategoryFilter(),
              
              if (state.isLoadingInitial)
                const DiscoverShimmer()
              else if (state.error != null && state.posts.isEmpty)
                ProfessionalErrorWidget(onRetry: () => ref.read(postsProvider.notifier).loadInitialPosts(null, tab: state.currentTab))
              else if (state.posts.isEmpty)
                const SliverFillRemaining(child: Center(child: Text("Aucune pépite trouvée ici.")))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      mainAxisSpacing: 12, 
                      crossAxisSpacing: 12, 
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ImmersiveCard(
                        key: ValueKey(state.posts[index].id), // Crucial pour le recyclage
                        post: state.posts[index],
                        allPosts: state.posts,
                        index: index,
                      ),
                      childCount: state.posts.length,
                    ),
                  ),
                ),
                
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20), 
                    child: Center(child: CircularProgressIndicator())
                  )
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}