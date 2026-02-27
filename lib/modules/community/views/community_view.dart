import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/post_controller.dart';
import 'widgets/post_card.dart';
import 'widgets/category_filter_bar.dart';

/// Community posts feed view.
///
/// Responsive: centres content with max-width 800 on wide screens (web/tablet).
/// Features: search, category filter, infinite scroll, FAB.
class CommunityView extends GetView<PostController> {
  const CommunityView({super.key});

  /// Max content width for wide screens (web / tablet landscape)
  static const double _maxContentWidth = 800;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Centre the content and limit width on wide screens
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: RefreshIndicator(
                onRefresh: controller.refreshPosts,
                color: AppConstants.primaryGreen,
                child: Column(
                  children: [
                    _buildSearchBar(),
                    const CategoryFilterBar(),
                    const SizedBox(height: 4),
                    Expanded(child: _buildPostsList()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // Floating button to create new post
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/community/create'),
        backgroundColor: AppConstants.primaryGreen,
        tooltip: 'Create Post',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Build the app bar with bookmark action
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Community'),
      centerTitle: true,
      backgroundColor: AppConstants.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        // Bookmark icon to view saved posts
        IconButton(
          icon: const Icon(Icons.bookmark_outline),
          onPressed: () => Get.toNamed('/community/bookmarks'),
          tooltip: 'Bookmarks',
        ),
      ],
    );
  }

  /// Simple search bar at the top of the feed
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller.searchTextController,
        decoration: InputDecoration(
          hintText: 'Search farming posts…',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 22),
          // Show clear button only when search is active
          suffixIcon: Obx(() => controller.isSearchActive.value
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: controller.clearSearch,
                )
              : const SizedBox.shrink()),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide:
                const BorderSide(color: AppConstants.primaryGreen, width: 1.5),
          ),
        ),
        onSubmitted: controller.performSearch,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  /// Build the posts list with loading states and infinite scroll.
  /// If search is active, shows search results instead.
  Widget _buildPostsList() {
    return Obx(() {
      // ---- Search active ----
      if (controller.isSearchActive.value) {
        if (controller.isSearching.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.primaryGreen),
          );
        }
        if (controller.searchResults.isEmpty) {
          return Center(
            child: Text(
              'No results found',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 80),
          itemCount: controller.searchResults.length,
          itemBuilder: (context, index) {
            final post = controller.searchResults[index];
            return Obx(() => PostCard(
                  post: post,
                  onTap: () => controller.navigateToPostDetail(post),
                  onBookmark: () => controller.toggleBookmark(post.id),
                  isBookmarked: controller.isBookmarked(post.id),
                  onDelete: controller.isPostAuthor(post.userId)
                      ? () => controller.deletePost(post.id)
                      : null,
                  onEdit: controller.isPostAuthor(post.userId)
                      ? () => Get.toNamed('/community/create', arguments: post)
                      : null,
                  onReport: !controller.isPostAuthor(post.userId)
                      ? () => controller.reportPost(post.id)
                      : null,
                ));
          },
        );
      }

      // ---- Normal feed ----
      // Show loading spinner on initial load
      if (controller.isLoading.value && controller.posts.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppConstants.primaryGreen),
        );
      }

      // Show empty state if no posts
      if (controller.posts.isEmpty) {
        return _buildEmptyState();
      }

      // Build list with infinite scroll
      return ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 80),
        itemCount: controller.posts.length + (controller.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Load more indicator at the end
          if (index == controller.posts.length) {
            controller.loadMore();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Obx(() => controller.isLoadingMore.value
                    ? const CircularProgressIndicator(
                        color: AppConstants.primaryGreen,
                      )
                    : const SizedBox.shrink()),
              ),
            );
          }

          // Build individual post card
          final post = controller.posts[index];
          return Obx(() => PostCard(
                post: post,
                onTap: () => controller.navigateToPostDetail(post),
                onBookmark: () => controller.toggleBookmark(post.id),
                isBookmarked: controller.isBookmarked(post.id),
                // Only show delete option for post author
                onDelete: controller.isPostAuthor(post.userId)
                    ? () => controller.deletePost(post.id)
                    : null,
                // Only show edit option for post author
                onEdit: controller.isPostAuthor(post.userId)
                    ? () => Get.toNamed('/community/create', arguments: post)
                    : null,
                // Show report option for non-authors
                onReport: !controller.isPostAuthor(post.userId)
                    ? () => controller.reportPost(post.id)
                    : null,
              ));
        },
      );
    });
  }

  /// Build empty state when no posts exist
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share something with the community!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/community/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
