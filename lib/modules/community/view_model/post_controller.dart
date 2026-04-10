import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/post_model.dart';
import '../repository/community_repository.dart';

/// Controller for managing posts, bookmarks, search, and category filters
/// Handles:
/// - Fetching posts with pagination
/// - Category filtering
/// - Bookmarking posts (subcollection-based)
/// - Deleting / editing posts
/// - Search (title + description)
/// - Report post
class PostController extends GetxController {
  /// Auth provider to access current user data
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  /// Community service for Firebase operations
  final CommunityRepository _communityRepository =
      Get.find<CommunityRepository>();

  /// This list holds all the posts we fetch from Firebase
  final RxList<PostModel> posts = <PostModel>[].obs;

  /// Shows loading spinner when true
  final RxBool isLoading = false.obs;

  /// Shows loading indicator for infinite scroll
  final RxBool isLoadingMore = false.obs;

  /// Currently selected category filter
  final RxString selectedCategory = 'all'.obs;

  /// List of post IDs that user has bookmarked
  final RxList<String> bookmarkedPostIds = <String>[].obs;

  /// List of actual bookmarked post objects for bookmarks view
  final RxList<PostModel> bookmarkedPostsList = <PostModel>[].obs;

  /// Loading state for bookmarks
  final RxBool isLoadingBookmarks = false.obs;

  // ==================== Search State ====================
  /// Current search query text
  final RxString searchQuery = ''.obs;

  /// Search results
  final RxList<PostModel> searchResults = <PostModel>[].obs;

  /// Whether a search is active (user typed something)
  final RxBool isSearchActive = false.obs;

  /// Loading state for search
  final RxBool isSearching = false.obs;

  /// Text controller for search field (disposed in onClose)
  final TextEditingController searchTextController = TextEditingController();

  // ==================== Pagination ====================
  /// Last document for Firestore pagination cursor
  DocumentSnapshot? _lastDocument;

  /// Whether there are more posts to load
  bool _hasMore = true;

  /// Getter for hasMore status
  bool get hasMore => _hasMore;

  /// Number of posts to fetch per page
  static const int _pageSize = 20;

  // ==================== State Management ====================
  /// Flag to track if controller is still active (for safe async operations)
  bool _isDisposed = false;

  /// Track if a bookmark operation is in progress for a specific post
  final Set<String> _bookmarkInProgress = {};

  /// Track if delete operation is in progress for a specific post
  final Set<String> _deleteInProgress = {};

  /// Navigation debounce duration in milliseconds
  static const int _navigationDebounceMs = 300;

  /// Track if navigation is in progress to prevent double navigation
  bool _isNavigating = false;

  /// Current post being viewed in detail
  final Rx<PostModel?> currentPost = Rx<PostModel?>(null);

  /// Get list of available categories including 'all'
  List<String> get categories => ['all', ...PostModel.categories];

  /// Get current user ID from auth provider
  String? get currentUserId => _authRepository.currentUser.value?.uid;

  /// Get current user name for displaying on posts
  String get currentUserName =>
      _authRepository.currentUser.value?.name ?? 'User';

  /// Get current user avatar URL
  String get currentUserAvatar =>
      _authRepository.currentUser.value?.profileImage ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchPosts();
    _loadBookmarks();
  }

  @override
  void onClose() {
    _isDisposed = true;
    searchTextController.dispose();
    super.onClose();
  }

  /// Load user's bookmarked posts (only IDs for quick checking)
  Future<void> _loadBookmarks() async {
    if (currentUserId == null || currentUserId!.isEmpty) return;

    try {
      final bookmarked = await _communityRepository.getBookmarkedPosts(
        currentUserId!,
      );
      if (_isDisposed) return;
      bookmarkedPostIds.value = bookmarked.map((p) => p.id).toList();
      bookmarkedPostsList.value = bookmarked;
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  /// Fetch bookmarked posts with full details for bookmarks view
  Future<void> fetchBookmarkedPosts() async {
    if (currentUserId == null || currentUserId!.isEmpty) return;
    if (isLoadingBookmarks.value) return;

    try {
      isLoadingBookmarks.value = true;
      final bookmarked = await _communityRepository.getBookmarkedPosts(
        currentUserId!,
      );
      if (_isDisposed) return;
      bookmarkedPostsList.value = bookmarked;
      bookmarkedPostIds.value = bookmarked.map((p) => p.id).toList();
    } catch (e) {
      debugPrint('Error fetching bookmarked posts: $e');
    } finally {
      if (!_isDisposed) {
        isLoadingBookmarks.value = false;
      }
    }
  }

  /// Fetch posts with optional refresh.
  ///
  /// When [refresh] is true (e.g. category change, pull-to-refresh), clears
  /// current list and resets pagination cursor before fetching.
  Future<void> fetchPosts({bool refresh = false}) async {
    // Allow refresh even while loading (category switch must not be blocked)
    if (isLoading.value && !refresh) return;

    try {
      if (refresh) {
        _lastDocument = null;
        _hasMore = true;
        posts.clear();
      }

      isLoading.value = true;

      final cat = selectedCategory.value == 'all'
          ? null
          : selectedCategory.value;

      final result = await _communityRepository.fetchPosts(
        lastDocument: _lastDocument,
        limit: _pageSize,
        category: cat,
      );

      if (_isDisposed) return;

      if (result.posts.isNotEmpty) {
        posts.addAll(result.posts);
      }

      // Update pagination cursor
      _lastDocument = result.lastDocument;

      // When no category filter, standard check works.
      // When category filter is active, the service over-fetches and filters,
      // so result.lastDocument == null is the real "end" signal.
      if (result.lastDocument == null) {
        _hasMore = false;
      } else if (cat == null) {
        // No filter — exact page-size check
        _hasMore = result.posts.length >= _pageSize;
      } else {
        // Category filter active — keep trying unless the raw batch was
        // completely exhausted (signalled by lastDocument being null above).
        _hasMore = true;
      }
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to load posts');
      }
      debugPrint('Error fetching posts: $e');
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  /// Load more posts for infinite scroll
  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value || isLoading.value) return;

    try {
      isLoadingMore.value = true;

      final cat = selectedCategory.value == 'all'
          ? null
          : selectedCategory.value;

      final result = await _communityRepository.fetchPosts(
        lastDocument: _lastDocument,
        limit: _pageSize,
        category: cat,
      );

      if (_isDisposed) return;

      if (result.posts.isNotEmpty) {
        posts.addAll(result.posts);
      }

      _lastDocument = result.lastDocument;

      if (result.lastDocument == null) {
        _hasMore = false;
      } else if (cat == null) {
        _hasMore = result.posts.length >= _pageSize;
      } else {
        _hasMore = true;
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
    } finally {
      if (!_isDisposed) {
        isLoadingMore.value = false;
      }
    }
  }

  /// Refresh posts (pull-to-refresh)
  Future<void> refreshPosts() async {
    await fetchPosts(refresh: true);
  }

  /// Filter posts by category
  void filterByCategory(String category) {
    if (selectedCategory.value != category) {
      debugPrint('[PostController] filterByCategory: "$category"');
      selectedCategory.value = category;
      // If search is active, re-run search with new category
      if (isSearchActive.value) {
        performSearch(searchQuery.value);
      } else {
        fetchPosts(refresh: true);
      }
    }
  }

  // ==================== Search ====================

  /// Perform search with current query and category filter
  Future<void> performSearch(String query) async {
    searchQuery.value = query.trim();

    if (searchQuery.value.isEmpty) {
      isSearchActive.value = false;
      searchResults.clear();
      return;
    }

    isSearchActive.value = true;
    isSearching.value = true;

    try {
      final results = await _communityRepository.searchPosts(
        searchQuery.value,
        category: selectedCategory.value == 'all'
            ? null
            : selectedCategory.value,
      );
      if (_isDisposed) return;

      // Client-side: also match description for broader results
      final lowerQuery = searchQuery.value.toLowerCase();
      final filtered = results
          .where(
            (p) =>
                p.title.toLowerCase().contains(lowerQuery) ||
                p.description.toLowerCase().contains(lowerQuery),
          )
          .toList();

      searchResults.assignAll(filtered);
    } catch (e) {
      debugPrint('Error searching posts: $e');
    } finally {
      if (!_isDisposed) {
        isSearching.value = false;
      }
    }
  }

  /// Clear search and return to normal feed
  void clearSearch() {
    searchTextController.clear();
    searchQuery.value = '';
    isSearchActive.value = false;
    searchResults.clear();
  }

  // ==================== Bookmarks ====================

  /// Toggle bookmark for a post (uses subcollection)
  Future<void> toggleBookmark(String postId) async {
    if (currentUserId == null || currentUserId!.isEmpty) {
      AppSnackbar.info('Please login to bookmark posts');
      return;
    }

    // Prevent multiple simultaneous bookmark operations on the same post
    if (_bookmarkInProgress.contains(postId)) return;
    _bookmarkInProgress.add(postId);

    try {
      final success = await _communityRepository.toggleBookmark(
        postId,
        currentUserId!,
      );
      if (_isDisposed) return;

      if (success) {
        if (bookmarkedPostIds.contains(postId)) {
          bookmarkedPostIds.remove(postId);
          bookmarkedPostsList.removeWhere((p) => p.id == postId);
        } else {
          bookmarkedPostIds.add(postId);
          final postIndex = posts.indexWhere((p) => p.id == postId);
          if (postIndex != -1 &&
              !bookmarkedPostsList.any((p) => p.id == postId)) {
            bookmarkedPostsList.add(posts[postIndex]);
          }
        }

        // Update local post if in list
        final index = posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = posts[index];
          final newBookmarkedBy = List<String>.from(post.bookmarkedBy);
          if (newBookmarkedBy.contains(currentUserId)) {
            newBookmarkedBy.remove(currentUserId);
          } else {
            newBookmarkedBy.add(currentUserId!);
          }
          posts[index] = post.copyWith(
            bookmarkedBy: newBookmarkedBy,
            bookmarksCount: newBookmarkedBy.length,
          );
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to update bookmark');
      }
      debugPrint('Error toggling bookmark: $e');
    } finally {
      _bookmarkInProgress.remove(postId);
    }
  }

  /// Check if post is bookmarked
  bool isBookmarked(String postId) {
    return bookmarkedPostIds.contains(postId);
  }

  // ==================== Post Actions ====================

  /// Delete a post
  Future<void> deletePost(String postId) async {
    if (_deleteInProgress.contains(postId)) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete'.tr),
        content: Text('cannot_be_undone'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _deleteInProgress.add(postId);

    try {
      isLoading.value = true;
      final success = await _communityRepository.deletePost(postId);
      if (_isDisposed) return;

      if (success) {
        posts.removeWhere((p) => p.id == postId);
        bookmarkedPostsList.removeWhere((p) => p.id == postId);
        bookmarkedPostIds.remove(postId);
        AppSnackbar.success('Post deleted successfully');

        if (currentPost.value?.id == postId) {
          Get.back();
        }
      } else {
        AppSnackbar.error('Failed to delete post');
      }
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to delete post');
      }
      debugPrint('Error deleting post: $e');
    } finally {
      _deleteInProgress.remove(postId);
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  /// Edit an existing post — updates title, description, category, and sets updatedAt
  Future<void> editPost({
    required String postId,
    required String title,
    required String description,
    required String category,
  }) async {
    try {
      isLoading.value = true;

      final success = await _communityRepository.updatePostFields(postId, {
        'title': title,
        'description': description,
        'category': category,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (_isDisposed) return;

      if (success) {
        // Update local post list
        final index = posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          posts[index] = posts[index].copyWith(
            title: title,
            description: description,
            category: category,
            updatedAt: DateTime.now(),
          );
        }

        // Update currentPost if viewing the edited post
        if (currentPost.value?.id == postId) {
          currentPost.value = currentPost.value!.copyWith(
            title: title,
            description: description,
            category: category,
            updatedAt: DateTime.now(),
          );
        }

        AppSnackbar.success('Post updated successfully');
      } else {
        AppSnackbar.error('Failed to update post');
      }
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to update post');
      }
      debugPrint('Error editing post: $e');
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  // ==================== Report Post ====================

  /// Report a post with a reason — shows dialog and sends to Firestore
  Future<void> reportPost(String postId) async {
    if (currentUserId == null || currentUserId!.isEmpty) {
      AppSnackbar.info('Please login to report posts');
      return;
    }

    final reasonController = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why are you reporting this post?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('submit'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (reason.isEmpty) {
      AppSnackbar.error('Please provide a reason');
      return;
    }

    try {
      final success = await _communityRepository.reportPost(
        postId: postId,
        reportedBy: currentUserId!,
        reason: reason,
      );

      if (success) {
        AppSnackbar.success('Post reported. We will review it.');
      } else {
        AppSnackbar.error('Failed to report post');
      }
    } catch (e) {
      AppSnackbar.error('Failed to report post');
      debugPrint('Error reporting post: $e');
    }
  }

  // ==================== Navigation ====================

  /// Set current post for detail view (used before navigation)
  void setCurrentPost(PostModel post) {
    currentPost.value = post;
  }

  /// Navigate to post detail with debounce to prevent double navigation
  Future<void> navigateToPostDetail(PostModel post) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      currentPost.value = post;
      await Get.toNamed('/community/post/${post.id}');
    } finally {
      Future.delayed(const Duration(milliseconds: _navigationDebounceMs), () {
        _isNavigating = false;
      });
    }
  }

  /// Load post details
  Future<void> loadPostDetails(String postId) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      final post = await _communityRepository.getPost(postId);
      if (_isDisposed) return;

      currentPost.value = post;
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to load post');
      }
      debugPrint('Error loading post: $e');
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  /// Check if current user is the post author
  bool isPostAuthor(String postUserId) {
    return currentUserId == postUserId;
  }

  /// Update comment count for current post
  void updateCommentCount(int delta) {
    if (currentPost.value != null) {
      currentPost.value = currentPost.value!.copyWith(
        commentsCount: (currentPost.value!.commentsCount + delta).clamp(
          0,
          999999,
        ),
      );
    }
  }
}
