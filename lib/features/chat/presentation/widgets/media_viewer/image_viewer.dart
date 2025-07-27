import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../core/services/download_service.dart';

class ImageViewer extends StatefulWidget {
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
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(widget.fileName ?? 'Image'),
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
        imageProvider: CachedNetworkImageProvider(widget.imageUrl),
        heroAttributes: widget.heroTag != null 
            ? PhotoViewHeroAttributes(tag: widget.heroTag!)
            : null,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.0,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Starting download...'),
          backgroundColor: Colors.blue,
        ),
      );

      final success = await DownloadService().downloadFile(widget.imageUrl, widget.fileName);
      
      if (!mounted) return;
      
      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Image downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to download image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error downloading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await SharePlus.instance.share(widget.imageUrl);
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error sharing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


}