import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../models/post_model.dart';

/// Post card widget for the community feed.
///
/// Image display:
/// - Uses 16:9 AspectRatio with rounded corners
/// - Single image → full card-width
/// - 2+ images   → first image large + "+N" overlay badge
/// - Tap image   → full-screen PageView viewer
///
/// Text:
/// - Title: max 2 lines
/// - Description: max 3 lines with ellipsis
/// - Timestamp: "Just now", "5m ago", "3h ago", "2d ago", "Feb 14"
class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onReport;
  final bool isBookmarked;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onBookmark,
    this.onDelete,
    this.onEdit,
    this.onReport,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildContent(),
            if (post.imageUrls.isNotEmpty) _buildImageSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────── HEADER ────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            child: post.userAvatarUrl.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: post.userAvatarUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      memCacheHeight: 80,
                      memCacheWidth: 80,
                      fadeInDuration: const Duration(milliseconds: 150),
                      fadeOutDuration: const Duration(milliseconds: 150),
                      errorWidget: (_, __, ___) =>
                          Icon(Icons.person, color: Colors.grey[500]),
                    ),
                  )
                : Icon(Icons.person, color: Colors.grey[500]),
          ),
          const SizedBox(width: 12),
          // User name + timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.userName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(post.createdAt),
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (post.updatedAt != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '· Edited',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Overflow menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            padding: EdgeInsets.zero,
            onSelected: _handleMenuAction,
            itemBuilder: (_) => _buildMenuItems(),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
      case 'report':
        onReport?.call();
        break;
      case 'share':
        Get.snackbar('Info', 'Share coming soon');
        break;
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    return [
      if (onEdit != null)
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 20),
            SizedBox(width: 12),
            Text('Edit'),
          ]),
        ),
      const PopupMenuItem(
        value: 'share',
        child: Row(children: [
          Icon(Icons.share_outlined, size: 20),
          SizedBox(width: 12),
          Text('Share'),
        ]),
      ),
      if (onReport != null)
        const PopupMenuItem(
          value: 'report',
          child: Row(children: [
            Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
            SizedBox(width: 12),
            Text('Report Post', style: TextStyle(color: Colors.orange)),
          ]),
        ),
      if (onDelete != null)
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 20),
            SizedBox(width: 12),
            Text('Delete', style: TextStyle(color: Colors.red)),
          ]),
        ),
    ];
  }

  // ──────────────────────────── CONTENT ───────────────────────────

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 10),
          // Title
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Description — limited to 3 lines
          Text(
            post.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── IMAGE ─────────────────────────────

  Widget _buildImageSection() {
    if (post.imageUrls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: GestureDetector(
        onTap: () => _openFullScreenViewer(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Always show the first image
                CachedNetworkImage(
                  imageUrl: post.imageUrls[0],
                  fit: BoxFit.cover,
                  memCacheHeight: 400,
                  memCacheWidth: 700,
                  fadeInDuration: const Duration(milliseconds: 200),
                  fadeOutDuration: const Duration(milliseconds: 200),
                  placeholder: (_, __) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child:
                        const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                // "+N" badge if there are more images
                if (post.imageUrls.length > 1)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '+${post.imageUrls.length - 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens a full-screen image viewer with PageView for swiping through images.
  void _openFullScreenViewer(int initialIndex) {
    Get.dialog(
      _FullScreenImageViewer(
        imageUrls: post.imageUrls,
        initialIndex: initialIndex,
      ),
      barrierColor: Colors.black87,
    );
  }

  // ──────────────────────────── FOOTER ────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Icon(Icons.comment_outlined, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text('${post.commentsCount}',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(width: 16),
          Icon(Icons.bookmark_border, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text('${post.bookmarksCount}',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const Spacer(),
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppConstants.primaryGreen : Colors.grey,
            ),
            onPressed: onBookmark,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── TIME FORMATTER ────────────────────

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return DateFormat('MMM d').format(dateTime);
    return DateFormat('MMM d, y').format(dateTime);
  }
}

// ════════════════════════════════════════════════════════════════════
// Full-screen image viewer (PageView) — opened by tapping post image
// ════════════════════════════════════════════════════════════════════

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // Swipeable images
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) {
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[i],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),
          // Close button
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Get.back(),
            ),
          ),
          // Page indicator (only if >1 image)
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
