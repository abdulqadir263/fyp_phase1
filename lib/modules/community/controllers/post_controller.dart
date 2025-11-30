import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/post_model.dart';
import '../services/community_service.dart';

/// Controller for managing posts, bookmarks, and category filters
/// Handles:
/// - Fetching posts with pagination
/// - Category filtering
/// - Bookmarking posts
/// - Deleting posts
class PostController extends GetxController {
  /// Auth provider to access current user data
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  
  /// Community service for Firebase operations
  final CommunityService _communityService = Get.find<CommunityService>();

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
  
  /// Track if navigation is in progress to prevent double navigation
  bool _isNavigating = false;

  /// Current post being viewed in detail
  final Rx<PostModel?> currentPost = Rx<PostModel?>(null);

  /// Get list of available categories including 'all'
  List<String> get categories => ['all', ...PostModel.categories];

  /// Get current user ID from auth provider
  String? get currentUserId => _authProvider.currentUser.value?.uid;

  /// Get current user name for displaying on posts
  String get currentUserName => _authProvider.currentUser.value?.name ?? 'User';

  /// Get current user avatar URL
  String get currentUserAvatar => _authProvider.currentUser.value?.profileImage ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchPosts();
    _loadBookmarks();
  }

  @override
  void onClose() {
    _isDisposed = true;
    super.onClose();
  }

  /// Load user's bookmarked posts (only IDs for quick checking)
  Future<void> _loadBookmarks() async {
    if (currentUserId == null || currentUserId == 'guest_user') return;
    
    try {
      final bookmarked = await _communityService.getBookmarkedPosts(currentUserId!);
      if (_isDisposed) return;
      bookmarkedPostIds.value = bookmarked.map((p) => p.id).toList();
      bookmarkedPostsList.value = bookmarked;
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  /// Fetch bookmarked posts with full details for bookmarks view
  Future<void> fetchBookmarkedPosts() async {
    if (currentUserId == null || currentUserId == 'guest_user') return;
    if (isLoadingBookmarks.value) return;
    
    try {
      isLoadingBookmarks.value = true;
      final bookmarked = await _communityService.getBookmarkedPosts(currentUserId!);
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

  /// Fetch posts with optional refresh
  Future<void> fetchPosts({bool refresh = false}) async {
    if (isLoading.value && !refresh) return;

    try {
      if (refresh) {
        _lastDocument = null;
        _hasMore = true;
        posts.clear();
      }

      isLoading.value = true;

      final result = await _communityService.fetchPosts(
        lastDocument: _lastDocument,
        limit: _pageSize,
        category: selectedCategory.value == 'all' ? null : selectedCategory.value,
      );
      
      if (_isDisposed) return;

      if (result.posts.isNotEmpty) {
        posts.addAll(result.posts);
        _lastDocument = result.lastDocument;
        _hasMore = result.posts.length >= _pageSize;
      } else {
        _hasMore = false;
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
      
      final result = await _communityService.fetchPosts(
        lastDocument: _lastDocument,
        limit: _pageSize,
        category: selectedCategory.value == 'all' ? null : selectedCategory.value,
      );
      
      if (_isDisposed) return;

      if (result.posts.isNotEmpty) {
        posts.addAll(result.posts);
        _lastDocument = result.lastDocument;
        _hasMore = result.posts.length >= _pageSize;
      } else {
        _hasMore = false;
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
      selectedCategory.value = category;
      fetchPosts(refresh: true);
    }
  }

  /// Toggle bookmark for a post
  Future<void> toggleBookmark(String postId) async {
    if (currentUserId == null || currentUserId == 'guest_user') {
      AppSnackbar.info('Please login to bookmark posts');
      return;
    }
    
    // Prevent multiple simultaneous bookmark operations on the same post
    if (_bookmarkInProgress.contains(postId)) return;
    _bookmarkInProgress.add(postId);

    try {
      final success = await _communityService.toggleBookmark(postId, currentUserId!);
      if (_isDisposed) return;
      
      if (success) {
        if (bookmarkedPostIds.contains(postId)) {
          bookmarkedPostIds.remove(postId);
          bookmarkedPostsList.removeWhere((p) => p.id == postId);
        } else {
          bookmarkedPostIds.add(postId);
          // Add post to bookmarkedPostsList if it exists in posts
          final postIndex = posts.indexWhere((p) => p.id == postId);
          if (postIndex != -1 && !bookmarkedPostsList.any((p) => p.id == postId)) {
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

  /// Delete a post
  Future<void> deletePost(String postId) async {
    // Prevent multiple simultaneous delete operations on the same post
    if (_deleteInProgress.contains(postId)) return;
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    
    _deleteInProgress.add(postId);

    try {
      isLoading.value = true;
      final success = await _communityService.deletePost(postId);
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

  /// Set current post for detail view (used before navigation)
  void setCurrentPost(PostModel post) {
    currentPost.value = post;
  }
  
  /// Navigate to post detail with debounce to prevent double navigation
  Future<void> navigateToPostDetail(PostModel post) async {
    // Prevent double navigation
    if (_isNavigating) return;
    _isNavigating = true;
    
    try {
      currentPost.value = post;
      await Get.toNamed('/community/post/${post.id}');
    } finally {
      // Reset after a short delay to allow navigation to complete
      Future.delayed(const Duration(milliseconds: 300), () {
        _isNavigating = false;
      });
    }
  }

  /// Load post details
  Future<void> loadPostDetails(String postId) async {
    if (isLoading.value) return;
    
    try {
      isLoading.value = true;
      final post = await _communityService.getPost(postId);
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
        commentsCount: (currentPost.value!.commentsCount + delta).clamp(0, 999999),
      );
    }
  }
}
