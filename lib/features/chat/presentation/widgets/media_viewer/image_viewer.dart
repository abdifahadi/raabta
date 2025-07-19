import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;
  final String? fileName;

  const ImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(
          fileName ?? 'Image',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            onPressed: () => _downloadImage(context),
            icon: const Icon(Icons.download),
            tooltip: 'Download',
          ),
          IconButton(
            onPressed: () => _shareImage(context),
            icon: const Icon(Icons.share),
            tooltip: 'Share',
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        heroAttributes: heroTag != null
            ? PhotoViewHeroAttributes(tag: heroTag!)
            : null,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4.0,
        loadingBuilder: (context, event) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: event == null
                    ? null
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading image...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadImage(BuildContext context) {
    // TODO: Implement image download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download functionality will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareImage(BuildContext context) {
    // TODO: Implement image sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Static method to show image viewer
  static void show(
    BuildContext context, {
    required String imageUrl,
    String? heroTag,
    String? fileName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          imageUrl: imageUrl,
          heroTag: heroTag,
          fileName: fileName,
        ),
      ),
    );
  }
}