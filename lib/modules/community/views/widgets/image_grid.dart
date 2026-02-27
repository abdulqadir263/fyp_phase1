import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

/// Widget for displaying images in post detail view.
///
/// - 1 image  → 16:9 AspectRatio, tap to fullscreen
/// - 2 images → side-by-side in 16:9, tap either for fullscreen PageView
/// - Uses rounded corners and BoxFit.cover for clean framing
class ImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final double height;

  const ImageGrid({
    super.key,
    required this.imageUrls,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return _buildSingleImage(imageUrls[0]);
    } else {
      return _buildMultipleImages();
    }
  }

  Widget _buildSingleImage(String url) {
    return GestureDetector(
      onTap: () => _openFullScreen(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            memCacheHeight: 440,
            memCacheWidth: 780,
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 200),
            placeholder: (_, __) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleImages() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Row(
          children: [
            // First image takes 60% width
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () => _openFullScreen(0),
                child: CachedNetworkImage(
                  imageUrl: imageUrls[0],
                  height: double.infinity,
                  fit: BoxFit.cover,
                  memCacheHeight: 440,
                  memCacheWidth: 440,
                  fadeInDuration: const Duration(milliseconds: 200),
                  fadeOutDuration: const Duration(milliseconds: 200),
                  placeholder: (_, __) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Second image takes 40% width, with "+N" overlay if >2
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _openFullScreen(1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrls[1],
                      fit: BoxFit.cover,
                      memCacheHeight: 440,
                      memCacheWidth: 300,
                      fadeInDuration: const Duration(milliseconds: 200),
                      fadeOutDuration: const Duration(milliseconds: 200),
                      placeholder: (_, __) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey),
                      ),
                    ),
                    if (imageUrls.length > 2)
                      Container(
                        color: Colors.black38,
                        alignment: Alignment.center,
                        child: Text(
                          '+${imageUrls.length - 2}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a full-screen PageView image viewer
  void _openFullScreen(int initialIndex) {
    Get.dialog(
      _DetailFullScreenViewer(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
      barrierColor: Colors.black87,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Full-screen image viewer for post detail view
// ════════════════════════════════════════════════════════════════════

class _DetailFullScreenViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _DetailFullScreenViewer({
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<_DetailFullScreenViewer> createState() =>
      _DetailFullScreenViewerState();
}

class _DetailFullScreenViewerState extends State<_DetailFullScreenViewer> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[i],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white),
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
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon:
                  const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Get.back(),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_page + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
