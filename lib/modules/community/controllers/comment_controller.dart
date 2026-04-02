import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/comment_model.dart';
import '../services/community_service.dart';
import 'post_controller.dart';

/// Controller for managing comments on posts
/// Handles:
/// - Loading comments for a post
/// - Adding new comments and replies
/// - Deleting comments
/// - Loading / collapsing reply threads
class CommentController extends GetxController {
  /// Auth provider to access current user data
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  
  /// Community service for Firebase operations
  final CommunityService _communityService = Get.find<CommunityService>();

  /// List of top-level comments for current post
  final RxList<CommentModel> comments = <CommentModel>[].obs;
  
  /// Controller for comment input
  final TextEditingController commentController = TextEditingController();
  
  /// Shows loading indicator while loading comments
  final RxBool isLoadingComments = false.obs;
  
  /// Shows loading indicator while adding a comment
  final RxBool isAddingComment = false.obs;
  
  /// Flag to track if controller is still active
  bool _isDisposed = false;

  // ==================== Reply State ====================

  /// The comment ID we are currently replying to (null = top-level comment)
  final Rx<String?> replyingToCommentId = Rx<String?>(null);

  /// Display name of the user we are replying to (for hint text)
  final RxString replyingToUserName = ''.obs;

  /// Map of parentCommentId → list of replies (loaded on demand)
  final RxMap<String, List<CommentModel>> repliesMap =
      <String, List<CommentModel>>{}.obs;

  /// Set of comment IDs whose reply threads are currently expanded
  final RxSet<String> expandedReplies = <String>{}.obs;

  /// Set of comment IDs whose replies are currently loading
  final RxSet<String> loadingReplies = <String>{}.obs;

  /// Get current user ID from auth provider
  String? get currentUserId => _authProvider.currentUser.value?.uid;

  /// Get current user name for displaying on comments
  String get currentUserName => _authProvider.currentUser.value?.name ?? 'User';

  /// Get current user avatar URL
  String get currentUserAvatar => _authProvider.currentUser.value?.profileImage ?? '';

  @override
  void onClose() {
    _isDisposed = true;
    commentController.dispose();
    super.onClose();
  }

  /// Clear comments when leaving post detail view
  void clearComments() {
    comments.clear();
    repliesMap.clear();
    expandedReplies.clear();
    cancelReply();
  }

  /// Load top-level comments for a post
  Future<void> loadComments(String postId) async {
    if (isLoadingComments.value || postId.isEmpty) return;
    
    try {
      isLoadingComments.value = true;
      final loadedComments = await _communityService.fetchComments(postId);
      if (_isDisposed) return;
      
      comments.assignAll(loadedComments);
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      if (!_isDisposed) {
        isLoadingComments.value = false;
      }
    }
  }

  // ==================== Reply Helpers ====================

  /// Start replying to a specific comment
  void startReply(String commentId, String userName) {
    replyingToCommentId.value = commentId;
    replyingToUserName.value = userName;
    // Focus hint will show "Replying to userName..."
  }

  /// Cancel the current reply (go back to top-level commenting)
  void cancelReply() {
    replyingToCommentId.value = null;
    replyingToUserName.value = '';
  }

  /// Load replies for a specific comment and expand the thread
  Future<void> toggleRepliesVisibility(String commentId) async {
    if (expandedReplies.contains(commentId)) {
      // Collapse
      expandedReplies.remove(commentId);
      return;
    }

    // Expand — load replies if not already loaded
    expandedReplies.add(commentId);

    if (!repliesMap.containsKey(commentId)) {
      await _loadReplies(commentId);
    }
  }

  /// Fetch replies from Firestore for a parent comment
  Future<void> _loadReplies(String parentCommentId) async {
    if (loadingReplies.contains(parentCommentId)) return;
    loadingReplies.add(parentCommentId);

    try {
      final replies = await _communityService.fetchReplies(parentCommentId);
      if (_isDisposed) return;
      repliesMap[parentCommentId] = replies;
    } catch (e) {
      debugPrint('Error loading replies: $e');
    } finally {
      loadingReplies.remove(parentCommentId);
    }
  }

  // ==================== Add / Delete ====================

  /// Add comment to current post.
  /// If [replyingToCommentId] is set, the comment becomes a reply.
  Future<bool> addComment(String postId, {String? parentCommentId}) async {
    final text = commentController.text.trim();
    if (text.isEmpty) return false;

    if (currentUserId == null || currentUserId!.isEmpty) {
      AppSnackbar.info('Please login to comment');
      return false;
    }

    if (postId.isEmpty) return false;
    
    // Prevent double submission
    if (isAddingComment.value) return false;

    // Use the controller-level reply target if caller didn't specify
    final effectiveParent = parentCommentId ?? replyingToCommentId.value;

    try {
      isAddingComment.value = true;
      
      final comment = CommentModel(
        id: '',
        postId: postId,
        userId: currentUserId!,
        userName: currentUserName,
        userAvatarUrl: currentUserAvatar,
        text: text,
        createdAt: DateTime.now(),
        parentCommentId: effectiveParent,
      );

      final commentId = await _communityService.addComment(comment);
      if (_isDisposed) return false;
      
      if (commentId != null) {
        commentController.clear();

        final newComment = comment.copyWith(id: commentId);

        if (effectiveParent != null && effectiveParent.isNotEmpty) {
          // It's a reply — add to repliesMap and auto-expand
          final existing = repliesMap[effectiveParent] ?? [];
          repliesMap[effectiveParent] = [...existing, newComment];
          expandedReplies.add(effectiveParent);
        } else {
          // Top-level comment
          comments.add(newComment);
        }

        // Cancel reply mode
        cancelReply();

        // Update post comment count
        if (Get.isRegistered<PostController>()) {
          Get.find<PostController>().updateCommentCount(1);
        }

        return true;
      }
      return false;
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to add comment');
      }
      debugPrint('Error adding comment: $e');
      return false;
    } finally {
      if (!_isDisposed) {
        isAddingComment.value = false;
      }
    }
  }

  /// Delete comment
  Future<bool> deleteComment(String commentId, String postId) async {
    if (postId.isEmpty || commentId.isEmpty) return false;

    try {
      final success = await _communityService.deleteComment(commentId, postId);
      if (_isDisposed) return false;
      
      if (success) {
        // Remove from top-level comments
        comments.removeWhere((c) => c.id == commentId);

        // Also remove from any reply list
        for (final key in repliesMap.keys.toList()) {
          repliesMap[key] = repliesMap[key]!
              .where((c) => c.id != commentId)
              .toList();
        }

        // Update post comment count
        if (Get.isRegistered<PostController>()) {
          Get.find<PostController>().updateCommentCount(-1);
        }

        return true;
      }
      return false;
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to delete comment');
      }
      debugPrint('Error deleting comment: $e');
      return false;
    }
  }

  /// Check if current user is the comment author
  bool isCommentAuthor(String commentUserId) {
    return currentUserId == commentUserId;
  }
}
