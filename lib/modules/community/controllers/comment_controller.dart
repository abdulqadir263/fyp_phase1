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
/// - Adding new comments
/// - Deleting comments
class CommentController extends GetxController {
  /// Auth provider to access current user data
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  
  /// Community service for Firebase operations
  final CommunityService _communityService = Get.find<CommunityService>();

  /// List of comments for current post
  final RxList<CommentModel> comments = <CommentModel>[].obs;
  
  /// Controller for comment input
  final TextEditingController commentController = TextEditingController();
  
  /// Shows loading indicator while loading comments
  final RxBool isLoadingComments = false.obs;
  
  /// Shows loading indicator while adding a comment
  final RxBool isAddingComment = false.obs;
  
  /// Flag to track if controller is still active
  bool _isDisposed = false;

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
  }

  /// Load comments for a post
  Future<void> loadComments(String postId) async {
    if (isLoadingComments.value || postId.isEmpty) return;
    
    try {
      isLoadingComments.value = true;
      final loadedComments = await _communityService.fetchComments(postId);
      if (_isDisposed) return;
      
      comments.assignAll(loadedComments);
    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (!_isDisposed) {
        // Don't show error for comments - fail silently
      }
    } finally {
      if (!_isDisposed) {
        isLoadingComments.value = false;
      }
    }
  }

  /// Add comment to current post
  Future<bool> addComment(String postId, {String? parentCommentId}) async {
    final text = commentController.text.trim();
    if (text.isEmpty) return false;

    if (currentUserId == null || currentUserId == 'guest_user') {
      AppSnackbar.info('Please login to comment');
      return false;
    }

    if (postId.isEmpty) return false;
    
    // Prevent double submission
    if (isAddingComment.value) return false;

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
        parentCommentId: parentCommentId,
      );

      final commentId = await _communityService.addComment(comment);
      if (_isDisposed) return false;
      
      if (commentId != null) {
        commentController.clear();
        
        // Add the new comment to the list locally for immediate feedback
        final newComment = comment.copyWith(id: commentId);
        comments.add(newComment);
        
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
        comments.removeWhere((c) => c.id == commentId);
        
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
