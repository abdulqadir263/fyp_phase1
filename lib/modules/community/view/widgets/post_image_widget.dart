import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? aspectRatio;
  final BorderRadiusGeometry? borderRadius;

  const PostImageWidget({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 1.2,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const SizedBox.shrink();

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image, color: Colors.grey),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image),
      ),
    );

    if (aspectRatio != null) {
      image = AspectRatio(
        aspectRatio: aspectRatio!,
        child: image,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: image,
    );
  }
}
