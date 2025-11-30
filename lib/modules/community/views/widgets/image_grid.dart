import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

/// Widget for displaying image grid (1 or 2 images)
/// Optimized with memory cache settings for better performance
class ImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final double height;

  const ImageGrid({
    super.key,
    required this.imageUrls,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return _buildSingleImage(imageUrls[0]);
    } else {
      return _buildDoubleImages();
    }
  }

  Widget _buildSingleImage(String url) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          memCacheHeight: 400,
          memCacheWidth: 600,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 200),
          placeholder: (_, __) => Container(
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoubleImages() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showFullScreenImage(imageUrls[0]),
              child: CachedNetworkImage(
                imageUrl: imageUrls[0],
                height: height,
                fit: BoxFit.cover,
                memCacheHeight: 300,
                memCacheWidth: 300,
                fadeInDuration: const Duration(milliseconds: 200),
                fadeOutDuration: const Duration(milliseconds: 200),
                placeholder: (_, __) => Container(
                  height: height,
                  color: Colors.grey[200],
                ),
                errorWidget: (_, __, ___) => Container(
                  height: height,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => _showFullScreenImage(imageUrls[1]),
              child: CachedNetworkImage(
                imageUrl: imageUrls[1],
                height: height,
                fit: BoxFit.cover,
                memCacheHeight: 300,
                memCacheWidth: 300,
                fadeInDuration: const Duration(milliseconds: 200),
                fadeOutDuration: const Duration(milliseconds: 200),
                placeholder: (_, __) => Container(
                  height: height,
                  color: Colors.grey[200],
                ),
                errorWidget: (_, __, ___) => Container(
                  height: height,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String url) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Full screen image
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
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
          ],
        ),
      ),
      barrierColor: Colors.black87,
    );
  }
}
