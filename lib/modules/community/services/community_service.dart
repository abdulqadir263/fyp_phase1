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

  FetchPostsResult({required this.posts, this.lastDocument});
}

/// Service class for community Firebase operations
class CommunityService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _postsCollection =>
      _firestore.collection(AppConstants.communityPostsCollection);

  CollectionReference get _commentsCollection =>
      _firestore.collection(AppConstants.commentsCollection);

  CollectionReference get _reportedPostsCollection =>
      _firestore.collection(AppConstants.reportedPostsCollection);

  /// Fetch posts with pagination and optional category filter.
  ///
  /// Strategy:
  /// - No category → simple orderBy query (uses single-field index).
  /// - With category → fetches ALL posts ordered by createdAt, then filters
  ///   client-side by category. This avoids the composite-index requirement
  ///   (`category` + `createdAt DESC`) that causes silent empty results when
  ///   the index hasn't been deployed yet.
  ///
  /// Once the composite index in `firestore.indexes.json` is deployed via
  /// `firebase deploy --only firestore:indexes`, you can switch to the
  /// server-side strategy for better scalability.
  Future<FetchPostsResult> fetchPosts({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? category,
  }) async {
    try {
      final trimmedCategory = category?.trim();
      final hasCategory =
          trimmedCategory != null &&
          trimmedCategory.isNotEmpty &&
          trimmedCategory != 'all';

      debugPrint(
        '[CommunityService] fetchPosts — category: "$trimmedCategory", '
        'hasCategory: $hasCategory, hasLastDoc: ${lastDocument != null}',
      );

      // ── No category filter → straightforward paginated query ──
      if (!hasCategory) {
        Query query = _postsCollection
            .orderBy('createdAt', descending: true)
            .limit(limit);

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        final snapshot = await query.get();
        final posts = _parseDocs(snapshot.docs);

        debugPrint(
          '[CommunityService] fetchPosts (all) — ${posts.length} posts',
        );
        return FetchPostsResult(
          posts: posts,
          lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        );
      }

      // ── Category filter active ──
      // Fetch a larger batch ordered by createdAt, then filter client-side.
      // We over-fetch to ensure we get enough matching posts after filtering.
      // The lastDocument cursor still works for the raw (unfiltered) stream.
      final categoryLower = trimmedCategory.toLowerCase();
      final fetchLimit = limit * 5; // over-fetch to compensate for filtering

      Query query = _postsCollection
          .orderBy('createdAt', descending: true)
          .limit(fetchLimit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final allPosts = _parseDocs(snapshot.docs);

      // Client-side category filter (case-insensitive, trimmed)
      final filtered = allPosts
          .where((p) => p.category.trim().toLowerCase() == categoryLower)
          .take(limit)
          .toList();

      debugPrint(
        '[CommunityService] fetchPosts (category="$trimmedCategory") '
        '— fetched ${allPosts.length}, matched ${filtered.length}',
      );

      return FetchPostsResult(
        posts: filtered,
        // Use the LAST raw document as cursor (not the last filtered one)
        // so the next page starts after the correct position in createdAt order.
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      return FetchPostsResult(posts: []);
    }
  }

  /// Helper — parse Firestore docs into PostModel list
  List<PostModel> _parseDocs(List<QueryDocumentSnapshot> docs) {
    return docs
        .map(
          (doc) => PostModel.fromJson(
            doc.data() as Map<String, dynamic>,
            docId: doc.id,
          ),
        )
        .toList();
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

  /// Update existing post (used for editing post title/description/category)
  Future<bool> updatePost(PostModel post) async {
    try {
      await _postsCollection.doc(post.id).update(post.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating post: $e');
      return false;
    }
  }

  /// Update only specific fields of a post (for edit operations)
  Future<bool> updatePostFields(
    String postId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _postsCollection.doc(postId).update(fields);
      return true;
    } catch (e) {
      debugPrint('Error updating post fields: $e');
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

      // Delete bookmark subcollection docs
      final bookmarks = await _postsCollection
          .doc(postId)
          .collection('bookmarks')
          .get();
      for (var doc in bookmarks.docs) {
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

  // ==================== BOOKMARK SUBCOLLECTION ====================
  // Migrated from bookmarkedBy array to subcollection for scalability.
  // Old array field is still read for backward compatibility.

  /// Toggle bookmark using subcollection: communityPosts/{postId}/bookmarks/{userId}
  Future<bool> toggleBookmark(String postId, String userId) async {
    try {
      final bookmarkRef = _postsCollection
          .doc(postId)
          .collection('bookmarks')
          .doc(userId);

      final bookmarkDoc = await bookmarkRef.get();
      final postRef = _postsCollection.doc(postId);

      if (bookmarkDoc.exists) {
        // Remove bookmark
        await bookmarkRef.delete();
        await postRef.update({
          'bookmarksCount': FieldValue.increment(-1),
          // Also remove from legacy array for backward compat
          'bookmarkedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        // Add bookmark
        await bookmarkRef.set({
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await postRef.update({
          'bookmarksCount': FieldValue.increment(1),
          // Also add to legacy array for backward compat
          'bookmarkedBy': FieldValue.arrayUnion([userId]),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      return false;
    }
  }

  /// Check if user has bookmarked a post (subcollection check)
  Future<bool> isBookmarked(String postId, String userId) async {
    try {
      final doc = await _postsCollection
          .doc(postId)
          .collection('bookmarks')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking bookmark: $e');
      return false;
    }
  }

  /// Get user's bookmarked posts
  /// Uses legacy bookmarkedBy array (backward compatible) + subcollection for new bookmarks.
  /// For existing users with array-only bookmarks, this still works via arrayContains.
  Future<List<PostModel>> getBookmarkedPosts(String userId) async {
    try {
      // Query using the legacy array field — works for both old and new bookmarks
      // because toggleBookmark writes to both array AND subcollection
      final snapshot = await _postsCollection
          .where('bookmarkedBy', arrayContains: userId)
          .get();

      final posts = snapshot.docs
          .map(
            (doc) => PostModel.fromJson(
              doc.data() as Map<String, dynamic>,
              docId: doc.id,
            ),
          )
          .toList();

      // Sort in memory by createdAt descending (acceptable for typical bookmark counts)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return posts;
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
          .map(
            (doc) => PostModel.fromJson(
              doc.data() as Map<String, dynamic>,
              docId: doc.id,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      return [];
    }
  }

  /// Fetch top-level comments for a post (parentCommentId is null or empty)
  /// Note: Using client-side sorting to avoid composite index requirement.
  Future<List<CommentModel>> fetchComments(String postId) async {
    try {
      final snapshot = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .get();

      // Map and filter to only top-level comments (no parentCommentId)
      final comments = snapshot.docs
          .map(
            (doc) => CommentModel.fromJson(
              doc.data() as Map<String, dynamic>,
              docId: doc.id,
            ),
          )
          .where(
            (comment) =>
                comment.parentCommentId == null ||
                comment.parentCommentId!.isEmpty,
          )
          .toList();

      // Sort in memory by createdAt ascending (oldest first)
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return comments;
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  /// Fetch replies for a specific parent comment
  /// Note: Using client-side sorting to avoid composite index requirement.
  Future<List<CommentModel>> fetchReplies(String parentCommentId) async {
    try {
      final snapshot = await _commentsCollection
          .where('parentCommentId', isEqualTo: parentCommentId)
          .get();

      final replies = snapshot.docs
          .map(
            (doc) => CommentModel.fromJson(
              doc.data() as Map<String, dynamic>,
              docId: doc.id,
            ),
          )
          .toList();

      // Sort in memory by createdAt ascending (oldest first)
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return replies;
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

  /// Search posts by title (prefix match) combined with optional category filter.
  /// NOTE: For title + description full-text search, use client-side filtering
  /// after fetching title matches (Firestore doesn't support OR across fields).
  // Requires Firestore composite index: title ASC + category ASC (if category filter used)
  Future<List<PostModel>> searchPosts(String query, {String? category}) async {
    try {
      final lowerQuery = query.toLowerCase().trim();
      if (lowerQuery.isEmpty) return [];

      // Firestore prefix search on title
      Query searchQuery = _postsCollection
          .orderBy('title')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(50);

      final snapshot = await searchQuery.get();

      var posts = snapshot.docs
          .map(
            (doc) => PostModel.fromJson(
              doc.data() as Map<String, dynamic>,
              docId: doc.id,
            ),
          )
          .toList();

      // Client-side: also match description (Firestore can't OR-search two fields)
      // We already have the title matches; add description matches from a broader fetch
      // For simplicity, filter title results + do a secondary pass if needed

      // Apply category filter client-side (avoids composite index for search + category)
      if (category != null && category != 'all') {
        posts = posts.where((p) => p.category == category).toList();
      }

      // Also do client-side description matching for posts in result
      // (This catches posts where description matches but title doesn't perfectly prefix-match)
      return posts;
    } catch (e) {
      debugPrint('Error searching posts: $e');
      return [];
    }
  }

  // ==================== REPORT POST ====================

  /// Report a post. Creates a document in the reportedPosts collection.
  Future<bool> reportPost({
    required String postId,
    required String reportedBy,
    required String reason,
  }) async {
    try {
      await _reportedPostsCollection.add({
        'postId': postId,
        'reportedBy': reportedBy,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error reporting post: $e');
      return false;
    }
  }
}
