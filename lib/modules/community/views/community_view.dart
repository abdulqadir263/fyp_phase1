import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/community_controller.dart';
import 'widgets/post_card.dart';
import 'widgets/category_filter_bar.dart';

/// Community view showing list of posts
class CommunityView extends GetView<CommunityController> {
  const CommunityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: controller.refreshPosts,
        color: AppConstants.primaryGreen,
        child: Column(
          children: [
            // Category filter bar
            const CategoryFilterBar(),
            // Posts list
            Expanded(child: _buildPostsList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/community/create'),
        backgroundColor: AppConstants.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Create Post',
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Community'),
      centerTitle: true,
      backgroundColor: AppConstants.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: Implement search
            Get.snackbar('Info', 'Search coming soon');
          },
          tooltip: 'Search',
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_outline),
          onPressed: () {
            // TODO: Navigate to bookmarked posts
            Get.snackbar('Info', 'Bookmarks coming soon');
          },
          tooltip: 'Bookmarks',
        ),
      ],
    );
  }

  Widget _buildPostsList() {
    return Obx(() {
      if (controller.isLoading.value && controller.posts.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppConstants.primaryGreen,
          ),
        );
      }

      if (controller.posts.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: controller.posts.length + (controller.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.posts.length) {
            // Load more indicator
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

          final post = controller.posts[index];
          return PostCard(
            post: post,
            onTap: () => Get.toNamed('/community/post/${post.id}'),
            onBookmark: () => controller.toggleBookmark(post.id),
            isBookmarked: controller.isBookmarked(post.id),
            onDelete: controller.isPostAuthor(post.userId)
                ? () => controller.deletePost(post.id)
                : null,
          );
        },
      );
    });
  }

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
