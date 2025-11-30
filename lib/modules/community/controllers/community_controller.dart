import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/data/services/cloudinary_service.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/community_service.dart';

/// This controller manages the community posts feed
/// It handles:
/// - Fetching posts from Firestore with pagination
/// - Creating new posts with images
/// - Deleting posts (only if you're the author)
/// - Bookmarking posts
/// - Loading and adding comments
class CommunityController extends GetxController {
  /// Auth provider to access current user data
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  
  /// Community service for Firebase operations
  final CommunityService _communityService = Get.find<CommunityService>();
  
  /// Image picker for selecting post images
  final ImagePicker _imagePicker = ImagePicker();

  /// This list holds all the posts we fetch from Firebase
  /// The 'Rx' makes it reactive - the UI updates automatically when this changes
  final RxList<PostModel> posts = <PostModel>[].obs;
  
  /// Shows loading spinner when true
  final RxBool isLoading = false.obs;
  
  /// Shows loading indicator for infinite scroll
  final RxBool isLoadingMore = false.obs;
  
  /// Currently selected category filter
  final RxString selectedCategory = 'all'.obs;
  
  /// List of post IDs that user has bookmarked
  final RxList<String> bookmarkedPosts = <String>[].obs;
  
  /// List of actual bookmarked post objects for bookmarks view
  final RxList<PostModel> bookmarkedPostsList = <PostModel>[].obs;
  
  /// Loading state for bookmarks
  final RxBool isLoadingBookmarks = false.obs;
  
  /// Search query for filtering posts (not yet implemented)
  final RxString searchQuery = ''.obs;

  // ==================== Pagination ====================
  /// Last document for Firestore pagination cursor
  DocumentSnapshot? _lastDocument;
  
  /// Whether there are more posts to load
  bool _hasMore = true;
  
  /// Number of posts to fetch per page
  static const int _pageSize = 20;
  
  // ==================== State Management ====================
  /// Flag to track if controller is still active (for safe async operations)
  bool _isDisposed = false;
  
  /// Track if a bookmark operation is in progress for a specific post
  final Set<String> _bookmarkInProgress = {};
  
  /// Track if delete operation is in progress for a specific post
  final Set<String> _deleteInProgress = {};

  // ==================== Create Post Variables ====================
  /// Controller for post title input
  final TextEditingController titleController = TextEditingController();
  
  /// Controller for post description input
  final TextEditingController descriptionController = TextEditingController();
  
  /// List of images selected for new post
  final RxList<File> selectedImages = <File>[].obs;
  
  /// Category selected for new post
  final RxString postCategory = 'crops'.obs;
  
  /// Shows loading indicator while creating post
  final RxBool isCreatingPost = false.obs;

  // ==================== Comments ====================
  /// List of comments for current post
  final RxList<CommentModel> comments = <CommentModel>[].obs;
  
  /// Controller for comment input
  final TextEditingController commentController = TextEditingController();
  
  /// Shows loading indicator while loading comments
  final RxBool isLoadingComments = false.obs;

  /// Current post being viewed in detail
  final Rx<PostModel?> currentPost = Rx<PostModel?>(null);

  /// Get list of available categories including 'all'
  List<String> get categories => ['all', ...PostModel.categories];

  @override
  void onInit() {
    super.onInit();
    fetchPosts();
    _loadBookmarks();
  }

  @override
  void onClose() {
    _isDisposed = true;
    titleController.dispose();
    descriptionController.dispose();
    commentController.dispose();
    super.onClose();
  }

  /// Get current user ID from auth provider
  String? get currentUserId => _authProvider.currentUser.value?.uid;

  /// Get current user name for displaying on posts
  String get currentUserName => _authProvider.currentUser.value?.name ?? 'User';

  /// Get current user avatar URL
  String get currentUserAvatar => _authProvider.currentUser.value?.profileImage ?? '';

  /// Load user's bookmarked posts (only IDs for quick checking)
  Future<void> _loadBookmarks() async {
    if (currentUserId == null || currentUserId == 'guest_user') return;
    
    try {
      final bookmarked = await _communityService.getBookmarkedPosts(currentUserId!);
      if (_isDisposed) return;
      bookmarkedPosts.value = bookmarked.map((p) => p.id).toList();
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
      bookmarkedPosts.value = bookmarked.map((p) => p.id).toList();
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
  /// Uses debouncing to prevent rapid toggle issues
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
        if (bookmarkedPosts.contains(postId)) {
          bookmarkedPosts.remove(postId);
        } else {
          bookmarkedPosts.add(postId);
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
        
        // Update bookmarkedPostsList - remove or add post
        if (bookmarkedPosts.contains(postId)) {
          // Was added to bookmarks, so add to the list
          final postIndex = posts.indexWhere((p) => p.id == postId);
          if (postIndex != -1 && !bookmarkedPostsList.any((p) => p.id == postId)) {
            bookmarkedPostsList.add(posts[postIndex]);
          }
        } else {
          // Was removed from bookmarks, so remove from the list
          bookmarkedPostsList.removeWhere((p) => p.id == postId);
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
    return bookmarkedPosts.contains(postId);
  }

  /// Delete a post
  /// Uses debouncing to prevent double-tap issues
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
        bookmarkedPosts.remove(postId);
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

  // ==================== CREATE POST ====================

  /// Pick images from gallery
  Future<void> pickImages() async {
    if (selectedImages.length >= 2) {
      AppSnackbar.info('Maximum 2 images allowed');
      return;
    }

    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        final remainingSlots = 2 - selectedImages.length;
        final filesToAdd = pickedFiles.take(remainingSlots);
        selectedImages.addAll(filesToAdd.map((xf) => File(xf.path)));
      }
    } catch (e) {
      AppSnackbar.error('Failed to pick images');
      debugPrint('Error picking images: $e');
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    if (selectedImages.length >= 2) {
      AppSnackbar.info('Maximum 2 images allowed');
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        selectedImages.add(File(pickedFile.path));
      }
    } catch (e) {
      AppSnackbar.error('Failed to take photo');
      debugPrint('Error taking photo: $e');
    }
  }

  /// Remove selected image
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  /// Clear create post form
  void clearCreatePostForm() {
    titleController.clear();
    descriptionController.clear();
    selectedImages.clear();
    postCategory.value = 'crops';
  }

  /// Validate create post form
  bool validateCreatePostForm() {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty || title.length < 5) {
      AppSnackbar.error('Title must be at least 5 characters');
      return false;
    }

    if (title.length > 100) {
      AppSnackbar.error('Title cannot exceed 100 characters');
      return false;
    }

    if (description.isEmpty || description.length < 20) {
      AppSnackbar.error('Description must be at least 20 characters');
      return false;
    }

    if (description.length > 1000) {
      AppSnackbar.error('Description cannot exceed 1000 characters');
      return false;
    }

    return true;
  }

  /// Create new post
  /// Uses parallel image uploads for better performance
  Future<void> createPost() async {
    // Prevent double submission
    if (isCreatingPost.value) return;
    
    if (!validateCreatePostForm()) return;
    if (currentUserId == null || currentUserId == 'guest_user') {
      AppSnackbar.info('Please login to create posts');
      return;
    }

    try {
      isCreatingPost.value = true;

      // Upload images to Cloudinary in parallel for better performance
      List<String> imageUrls = [];
      if (selectedImages.isNotEmpty) {
        final cloudinaryService = Get.find<CloudinaryService>();
        final uploadFutures = selectedImages.map(
          (image) => cloudinaryService.uploadImage(image, 'post_images').catchError((e) {
            debugPrint('Error uploading image: $e');
            return null;
          }),
        );
        final results = await Future.wait(uploadFutures);
        imageUrls = results.whereType<String>().toList();
        
        // Warn user if some images failed to upload
        final failedCount = selectedImages.length - imageUrls.length;
        if (failedCount > 0 && imageUrls.isNotEmpty) {
          AppSnackbar.info('$failedCount image(s) failed to upload');
        } else if (failedCount > 0 && imageUrls.isEmpty) {
          // All images failed, but continue with post creation without images
          debugPrint('All image uploads failed, continuing with text-only post');
        }
      }
      
      if (_isDisposed) return;

      // Create post model
      final post = PostModel(
        id: '',
        userId: currentUserId!,
        userName: currentUserName,
        userAvatarUrl: currentUserAvatar,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        imageUrls: imageUrls,
        category: postCategory.value,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      final postId = await _communityService.createPost(post);
      
      if (_isDisposed) return;

      if (postId != null) {
        AppSnackbar.success('Post created successfully');
        clearCreatePostForm();
        Get.back();
        fetchPosts(refresh: true);
      } else {
        AppSnackbar.error('Failed to create post');
      }
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to create post');
      }
      debugPrint('Error creating post: $e');
    } finally {
      if (!_isDisposed) {
        isCreatingPost.value = false;
      }
    }
  }

  // ==================== POST DETAIL & COMMENTS ====================

  /// Set current post for detail view (used before navigation)
  void setCurrentPost(PostModel post) {
    currentPost.value = post;
    // Clear existing comments and load new ones for this post
    comments.clear();
    // Load comments asynchronously - don't block navigation
    _loadCommentsAsync(post.id);
  }
  
  /// Load comments asynchronously without blocking
  void _loadCommentsAsync(String postId) {
    if (!isLoadingComments.value) {
      loadComments(postId);
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
      
      if (post != null) {
        await loadComments(postId);
      }
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

  /// Load comments for current post
  Future<void> loadComments(String postId) async {
    if (isLoadingComments.value) return;
    
    try {
      isLoadingComments.value = true;
      final loadedComments = await _communityService.fetchComments(postId);
      if (_isDisposed) return;
      
      comments.value = loadedComments;
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      if (!_isDisposed) {
        isLoadingComments.value = false;
      }
    }
  }

  /// Add comment to current post
  Future<void> addComment({String? parentCommentId}) async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    if (currentUserId == null || currentUserId == 'guest_user') {
      AppSnackbar.info('Please login to comment');
      return;
    }

    if (currentPost.value == null) return;

    try {
      final comment = CommentModel(
        id: '',
        postId: currentPost.value!.id,
        userId: currentUserId!,
        userName: currentUserName,
        userAvatarUrl: currentUserAvatar,
        text: text,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      final commentId = await _communityService.addComment(comment);
      if (_isDisposed) return;
      
      if (commentId != null) {
        commentController.clear();
        await loadComments(currentPost.value!.id);
        
        // Update comments count in current post
        if (currentPost.value != null) {
          currentPost.value = currentPost.value!.copyWith(
            commentsCount: currentPost.value!.commentsCount + 1,
          );
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to add comment');
      }
      debugPrint('Error adding comment: $e');
    }
  }

  /// Delete comment
  Future<void> deleteComment(String commentId) async {
    if (currentPost.value == null) return;

    try {
      final success = await _communityService.deleteComment(
        commentId,
        currentPost.value!.id,
      );
      if (_isDisposed) return;
      
      if (success) {
        await loadComments(currentPost.value!.id);
        
        // Update comments count in current post
        if (currentPost.value != null) {
          currentPost.value = currentPost.value!.copyWith(
            commentsCount: (currentPost.value!.commentsCount - 1).clamp(0, 999999),
          );
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to delete comment');
      }
      debugPrint('Error deleting comment: $e');
    }
  }

  /// Check if current user is the post author
  bool isPostAuthor(String postUserId) {
    return currentUserId == postUserId;
  }

  /// Check if current user is the comment author
  bool isCommentAuthor(String commentUserId) {
    return currentUserId == commentUserId;
  }
}
