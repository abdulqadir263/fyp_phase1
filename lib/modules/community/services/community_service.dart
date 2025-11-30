import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

/// Result class for paginated post fetching
class FetchPostsResult {
  final List<PostModel> posts;
  final DocumentSnapshot? lastDocument;

  FetchPostsResult({
    required this.posts,
    this.lastDocument,
  });
}

/// Service class for community Firebase operations
class CommunityService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _postsCollection =>
      _firestore.collection(AppConstants.communityPostsCollection);

  CollectionReference get _commentsCollection =>
      _firestore.collection(AppConstants.commentsCollection);

  /// Fetch posts with pagination
  /// Returns a [FetchPostsResult] containing posts and the last document for pagination
  Future<FetchPostsResult> fetchPosts({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? category,
  }) async {
    try {
      Query query = _postsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final posts = snapshot.docs
          .map((doc) => PostModel.fromJson(
                doc.data() as Map<String, dynamic>,
                docId: doc.id,
              ))
          .toList();
      
      return FetchPostsResult(
        posts: posts,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      return FetchPostsResult(posts: []);
    }
  }

  /// Get single post by ID
  Future<PostModel?> getPost(String postId) async {
    try {
      final doc = await _postsCollection.doc(postId).get();
      if (doc.exists) {
        return PostModel.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting post: $e');
      return null;
    }
  }

  /// Create new post
  Future<String?> createPost(PostModel post) async {
    try {
      final docRef = await _postsCollection.add(post.toJson());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  /// Update existing post
  Future<bool> updatePost(PostModel post) async {
    try {
      await _postsCollection.doc(post.id).update(post.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating post: $e');
      return false;
    }
  }

  /// Delete post
  Future<bool> deletePost(String postId) async {
    try {
      // Delete all comments for the post first
      final comments = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in comments.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the post
      batch.delete(_postsCollection.doc(postId));
      await batch.commit();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  /// Toggle bookmark for post
  Future<bool> toggleBookmark(String postId, String userId) async {
    try {
      final postRef = _postsCollection.doc(postId);
      
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);
        if (!snapshot.exists) return false;

        final post = PostModel.fromJson(
          snapshot.data() as Map<String, dynamic>,
          docId: snapshot.id,
        );

        List<String> bookmarkedBy = List.from(post.bookmarkedBy);
        int bookmarksCount = post.bookmarksCount;

        if (bookmarkedBy.contains(userId)) {
          bookmarkedBy.remove(userId);
          bookmarksCount = bookmarksCount > 0 ? bookmarksCount - 1 : 0;
        } else {
          bookmarkedBy.add(userId);
          bookmarksCount++;
        }

        transaction.update(postRef, {
          'bookmarkedBy': bookmarkedBy,
          'bookmarksCount': bookmarksCount,
        });

        return true;
      });
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      return false;
    }
  }

  /// Get user's bookmarked posts
  Future<List<PostModel>> getBookmarkedPosts(String userId) async {
    try {
      final snapshot = await _postsCollection
          .where('bookmarkedBy', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PostModel.fromJson(
                doc.data() as Map<String, dynamic>,
                docId: doc.id,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting bookmarked posts: $e');
      return [];
    }
  }

  /// Get user's posts
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final snapshot = await _postsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PostModel.fromJson(
                doc.data() as Map<String, dynamic>,
                docId: doc.id,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      return [];
    }
  }

  /// Fetch comments for a post
  Future<List<CommentModel>> fetchComments(String postId) async {
    try {
      // First, get all comments for this post
      final snapshot = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .get();

      // Filter to only top-level comments (no parentCommentId)
      return snapshot.docs
          .map((doc) => CommentModel.fromJson(
                doc.data() as Map<String, dynamic>,
                docId: doc.id,
              ))
          .where((comment) => comment.parentCommentId == null || comment.parentCommentId!.isEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  /// Fetch replies for a comment
  Future<List<CommentModel>> fetchReplies(String parentCommentId) async {
    try {
      final snapshot = await _commentsCollection
          .where('parentCommentId', isEqualTo: parentCommentId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => CommentModel.fromJson(
                doc.data() as Map<String, dynamic>,
                docId: doc.id,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error fetching replies: $e');
      return [];
    }
  }

  /// Add comment to post
  Future<String?> addComment(CommentModel comment) async {
    try {
      final docRef = await _commentsCollection.add(comment.toJson());
      
      // Update comments count on post
      await _postsCollection.doc(comment.postId).update({
        'commentsCount': FieldValue.increment(1),
      });
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  /// Delete comment
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      await _commentsCollection.doc(commentId).delete();
      
      // Update comments count on post
      await _postsCollection.doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      return false;
    }
  }

  /// Search posts
  Future<List<PostModel>> searchPosts(String query) async {
    try {
      // Simple search - for production, use Algolia or similar
      final snapshot = await _postsCollection
          .orderBy('title')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => PostModel.fromJson(
                doc.data() as Map<String, dynamic>,
                docId: doc.id,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error searching posts: $e');
      return [];
    }
  }
}
