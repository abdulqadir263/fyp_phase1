import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../view_model/post_controller.dart';
import '../view_model/comment_controller.dart';
import '../models/post_model.dart';
import 'widgets/comment_item.dart';
import 'widgets/image_grid.dart';

/// View for displaying post details with comments and reply support
class PostDetailView extends StatefulWidget {
  const PostDetailView({super.key});

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  late final PostController postController;
  late final CommentController commentController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    postController = Get.find<PostController>();
    commentController = Get.find<CommentController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPostIfNeeded();
    });
  }

  @override
  void dispose() {
    commentController.clearComments();
    super.dispose();
  }

  void _loadPostIfNeeded() {
    if (_initialized) return;
    _initialized = true;

    final postId = Get.parameters['id'];
    if (postId != null && postId.isNotEmpty) {
      if (postController.currentPost.value?.id != postId) {
        postController.loadPostDetails(postId);
      }
      commentController.loadComments(postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: ResponsiveHelper.tabletCenter(
        child: Obx(() {
          if (postController.isLoading.value &&
              postController.currentPost.value == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryGreen,
              ),
            );
          }

          final post = postController.currentPost.value;
          if (post == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Post not found',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPostContent(post),
                      const Divider(height: 1),
                      _buildCommentsSection(),
                    ],
                  ),
                ),
              ),
              // Reply indicator bar + comment input
              _buildReplyIndicator(),
              _buildCommentInput(),
            ],
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('post'.tr),
      centerTitle: true,
      backgroundColor: AppConstants.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        Obx(() {
          final post = postController.currentPost.value;
          if (post == null) return const SizedBox.shrink();

          return PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Get.toNamed('/community/create', arguments: post);
                  break;
                case 'delete':
                  postController.deletePost(post.id);
                  break;
                case 'report':
                  postController.reportPost(post.id);
                  break;
                case 'share':
                  Get.snackbar('Info', 'Share coming soon');
                  break;
              }
            },
            itemBuilder: (context) => [
              if (postController.isPostAuthor(post.userId))
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Share'),
                  ],
                ),
              ),
              if (!postController.isPostAuthor(post.userId))
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Report Post',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              if (postController.isPostAuthor(post.userId))
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPostContent(PostModel post) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                child: post.userAvatarUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: post.userAvatarUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Icon(Icons.person, color: Colors.grey[500]),
                        ),
                      )
                    : Icon(Icons.person, color: Colors.grey[500]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _formatTimeAgo(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                        // "Edited" label if post was updated
                        if (post.updatedAt != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· Edited',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Bookmark button
              Obx(
                () => IconButton(
                  icon: Icon(
                    postController.isBookmarked(post.id)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: postController.isBookmarked(post.id)
                        ? AppConstants.primaryGreen
                        : Colors.grey,
                  ),
                  onPressed: () => postController.toggleBookmark(post.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            post.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              PostModel.getCategoryDisplayName(post.category),
              style: const TextStyle(
                color: AppConstants.primaryGreen,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Images
          if (post.imageUrls.isNotEmpty) ...[
            ImageGrid(imageUrls: List<String>.from(post.imageUrls)),
            const SizedBox(height: 16),
          ],
          // Description
          Text(
            post.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Obx(
            () => Row(
              children: [
                Icon(Icons.comment_outlined, size: 18, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${postController.currentPost.value?.commentsCount ?? 0} comments',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.bookmark_border, size: 18, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${post.bookmarksCount} bookmarks',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Comments section with reply thread support
  Widget _buildCommentsSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (commentController.isLoadingComments.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryGreen,
                  ),
                ),
              );
            }

            if (commentController.comments.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No comments yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to comment!',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: commentController.comments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final comment = commentController.comments[index];
                return _buildCommentWithReplies(comment);
              },
            );
          }),
        ],
      ),
    );
  }

  /// Build a single comment with its collapsible reply thread
  Widget _buildCommentWithReplies(comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top-level comment
        CommentItem(
          comment: comment,
          onDelete: commentController.isCommentAuthor(comment.userId)
              ? () {
                  final postId = postController.currentPost.value?.id;
                  if (postId != null) {
                    commentController.deleteComment(comment.id, postId);
                  }
                }
              : null,
          onReply: () =>
              commentController.startReply(comment.id, comment.userName),
        ),
        // Reply thread (collapsible)
        Obx(() {
          final replies = commentController.repliesMap[comment.id] ?? [];
          final isExpanded = commentController.expandedReplies.contains(
            comment.id,
          );
          final isLoading = commentController.loadingReplies.contains(
            comment.id,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "View replies" / "Hide replies" toggle
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: GestureDetector(
                  onTap: () =>
                      commentController.toggleRepliesVisibility(comment.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isExpanded ? 'Hide replies' : 'View replies',
                            style: TextStyle(
                              color: AppConstants.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ),
              // Render replies indented when expanded
              if (isExpanded && replies.isNotEmpty)
                ...replies.map(
                  (reply) => CommentItem(
                    comment: reply,
                    onDelete: commentController.isCommentAuthor(reply.userId)
                        ? () {
                            final postId = postController.currentPost.value?.id;
                            if (postId != null) {
                              commentController.deleteComment(reply.id, postId);
                            }
                          }
                        : null,
                    // No nested reply support (one level only)
                    onReply: null,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  /// Small bar showing "Replying to UserName" when reply mode is active
  Widget _buildReplyIndicator() {
    return Obx(() {
      if (commentController.replyingToCommentId.value == null) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: Colors.grey[200],
        child: Row(
          children: [
            Text(
              'Replying to ${commentController.replyingToUserName.value}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: commentController.cancelReply,
              child: Icon(Icons.close, size: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => TextField(
                  controller: commentController.commentController,
                  decoration: InputDecoration(
                    hintText:
                        commentController.replyingToCommentId.value != null
                        ? 'Write a reply...'
                        : 'Write a comment...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => Material(
                color: commentController.isAddingComment.value
                    ? Colors.grey
                    : AppConstants.primaryGreen,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: commentController.isAddingComment.value
                      ? null
                      : () {
                          final postId = postController.currentPost.value?.id;
                          if (postId != null) {
                            commentController.addComment(postId);
                          }
                        },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: commentController.isAddingComment.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
