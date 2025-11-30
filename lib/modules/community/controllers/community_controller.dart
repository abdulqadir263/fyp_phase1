import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/data/services/cloudinary_service.dart';
import '../../../core/constants/app_constants.dart';
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
  DocumentSnapshot? lastDocument;
  
  /// Whether there are more posts to load
  bool hasMore = true;
  
  /// Number of posts to fetch per page
  static const int pageSize = 20;

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
      bookmarkedPostsList.value = bookmarked;
      bookmarkedPosts.value = bookmarked.map((p) => p.id).toList();
    } catch (e) {
      debugPrint('Error fetching bookmarked posts: $e');
    } finally {
      isLoadingBookmarks.value = false;
    }
  }

  /// Fetch posts with optional refresh
  Future<void> fetchPosts({bool refresh = false}) async {
    if (isLoading.value) return;

    try {
      if (refresh) {
        lastDocument = null;
        hasMore = true;
        posts.clear();
      }

      isLoading.value = true;

      final newPosts = await _communityService.fetchPosts(
        lastDocument: lastDocument,
        limit: pageSize,
        category: selectedCategory.value == 'all' ? null : selectedCategory.value,
      );

      if (newPosts.isNotEmpty) {
        posts.addAll(newPosts);
        hasMore = newPosts.length >= pageSize;
      } else {
        hasMore = false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load posts');
      debugPrint('Error fetching posts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more posts for infinite scroll
  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      await fetchPosts();
    } finally {
      isLoadingMore.value = false;
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
      Get.snackbar('Info', 'Please login to bookmark posts');
      return;
    }

    try {
      final success = await _communityService.toggleBookmark(postId, currentUserId!);
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
          final postToAdd = posts.firstWhereOrNull((p) => p.id == postId);
          if (postToAdd != null && !bookmarkedPostsList.any((p) => p.id == postId)) {
            bookmarkedPostsList.add(postToAdd);
          }
        } else {
          // Was removed from bookmarks, so remove from the list
          bookmarkedPostsList.removeWhere((p) => p.id == postId);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update bookmark');
      debugPrint('Error toggling bookmark: $e');
    }
  }

  /// Check if post is bookmarked
  bool isBookmarked(String postId) {
    return bookmarkedPosts.contains(postId);
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
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

    try {
      isLoading.value = true;
      final success = await _communityService.deletePost(postId);
      if (success) {
        posts.removeWhere((p) => p.id == postId);
        Get.snackbar('Success', 'Post deleted successfully');
        
        if (currentPost.value?.id == postId) {
          Get.back();
        }
      } else {
        Get.snackbar('Error', 'Failed to delete post');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete post');
      debugPrint('Error deleting post: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== CREATE POST ====================

  /// Pick images from gallery
  Future<void> pickImages() async {
    if (selectedImages.length >= 2) {
      Get.snackbar('Info', 'Maximum 2 images allowed');
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
      Get.snackbar('Error', 'Failed to pick images');
      debugPrint('Error picking images: $e');
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    if (selectedImages.length >= 2) {
      Get.snackbar('Info', 'Maximum 2 images allowed');
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
      Get.snackbar('Error', 'Failed to take photo');
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
      Get.snackbar('Error', 'Title must be at least 5 characters');
      return false;
    }

    if (title.length > 100) {
      Get.snackbar('Error', 'Title cannot exceed 100 characters');
      return false;
    }

    if (description.isEmpty || description.length < 20) {
      Get.snackbar('Error', 'Description must be at least 20 characters');
      return false;
    }

    if (description.length > 1000) {
      Get.snackbar('Error', 'Description cannot exceed 1000 characters');
      return false;
    }

    return true;
  }

  /// Create new post
  Future<void> createPost() async {
    if (!validateCreatePostForm()) return;
    if (currentUserId == null || currentUserId == 'guest_user') {
      Get.snackbar('Info', 'Please login to create posts');
      return;
    }

    try {
      isCreatingPost.value = true;

      // Upload images to Cloudinary
      List<String> imageUrls = [];
      if (selectedImages.isNotEmpty) {
        final cloudinaryService = Get.find<CloudinaryService>();
        for (var image in selectedImages) {
          final url = await cloudinaryService.uploadImage(image, 'post_images');
          if (url != null) {
            imageUrls.add(url);
          }
        }
      }

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

      if (postId != null) {
        Get.snackbar('Success', 'Post created successfully');
        clearCreatePostForm();
        Get.back();
        fetchPosts(refresh: true);
      } else {
        Get.snackbar('Error', 'Failed to create post');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create post');
      debugPrint('Error creating post: $e');
    } finally {
      isCreatingPost.value = false;
    }
  }

  // ==================== POST DETAIL & COMMENTS ====================

  /// Set current post for detail view (used before navigation)
  void setCurrentPost(PostModel post) {
    currentPost.value = post;
    // Clear existing comments and load new ones for this post
    comments.clear();
    // Load comments only if not already loading
    if (!isLoadingComments.value) {
      loadComments(post.id);
    }
  }

  /// Load post details
  Future<void> loadPostDetails(String postId) async {
    try {
      isLoading.value = true;
      final post = await _communityService.getPost(postId);
      currentPost.value = post;
      
      if (post != null) {
        await loadComments(postId);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load post');
      debugPrint('Error loading post: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load comments for current post
  Future<void> loadComments(String postId) async {
    try {
      isLoadingComments.value = true;
      final loadedComments = await _communityService.fetchComments(postId);
      comments.value = loadedComments;
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      isLoadingComments.value = false;
    }
  }

  /// Add comment to current post
  Future<void> addComment({String? parentCommentId}) async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    if (currentUserId == null || currentUserId == 'guest_user') {
      Get.snackbar('Info', 'Please login to comment');
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
      
      if (commentId != null) {
        commentController.clear();
        await loadComments(currentPost.value!.id);
        
        // Update comments count in current post
        currentPost.value = currentPost.value!.copyWith(
          commentsCount: currentPost.value!.commentsCount + 1,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add comment');
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
      
      if (success) {
        await loadComments(currentPost.value!.id);
        
        // Update comments count in current post
        currentPost.value = currentPost.value!.copyWith(
          commentsCount: currentPost.value!.commentsCount - 1,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete comment');
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
