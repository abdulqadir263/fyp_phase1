import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../controllers/post_controller.dart';
import 'widgets/post_card.dart';

/// View for displaying bookmarked posts
class BookmarksView extends StatefulWidget {
  const BookmarksView({super.key});

  @override
  State<BookmarksView> createState() => _BookmarksViewState();
}

class _BookmarksViewState extends State<BookmarksView> {
  late final PostController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PostController>();
    // Fetch bookmarked posts when view is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchBookmarkedPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('bookmarks'.tr),
        centerTitle: true,
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: ResponsiveHelper.tabletCenter(
        child: Obx(() {
        if (controller.isLoadingBookmarks.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppConstants.primaryGreen,
            ),
          );
        }

        final bookmarkedPosts = controller.bookmarkedPostsList;

        if (bookmarkedPosts.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.fetchBookmarkedPosts,
          color: AppConstants.primaryGreen,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: bookmarkedPosts.length,
            itemBuilder: (context, index) {
              final post = bookmarkedPosts[index];
              return Obx(() => PostCard(
                post: post,
                onTap: () => controller.navigateToPostDetail(post),
                onBookmark: () => controller.toggleBookmark(post.id),
                isBookmarked: controller.isBookmarked(post.id),
                onDelete: controller.isPostAuthor(post.userId)
                    ? () => controller.deletePost(post.id)
                    : null,
              ));
            },
          ),
        );
      }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No bookmarks yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save posts you want to read later by tapping the bookmark icon',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
              label: Text('browse_posts'.tr),
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
