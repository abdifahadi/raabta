import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/services/media_picker_service.dart';

class MediaPickerBottomSheet extends StatelessWidget {
  final Function(PickedMediaFile) onMediaSelected;

  const MediaPickerBottomSheet({
    super.key,
    required this.onMediaSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          const Text(
            'Select Media',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Media options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaOption(
                context,
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.blue,
                onTap: () => _pickFromCamera(context),
              ),
              _buildMediaOption(
                context,
                icon: Icons.photo,
                label: 'Gallery',
                color: Colors.green,
                onTap: () => _pickFromGallery(context),
              ),
              _buildMediaOption(
                context,
                icon: Icons.videocam,
                label: 'Video',
                color: Colors.red,
                onTap: () => _pickVideo(context),
              ),
              _buildMediaOption(
                context,
                icon: Icons.attach_file,
                label: 'Document',
                color: Colors.orange,
                onTap: () => _pickDocument(context),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Additional options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaOption(
                context,
                icon: Icons.mic,
                label: 'Audio',
                color: Colors.purple,
                onTap: () => _pickAudio(context),
              ),
              _buildMediaOption(
                context,
                icon: Icons.folder,
                label: 'Files',
                color: Colors.teal,
                onTap: () => _pickAnyFile(context),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    try {
      final mediaService = MediaPickerService();
      final pickedFile = await mediaService.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        onMediaSelected(pickedFile);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to pick from camera: ${e.toString()}');
      }
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final mediaService = MediaPickerService();
      final pickedFile = await mediaService.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        onMediaSelected(pickedFile);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to pick from gallery: ${e.toString()}');
      }
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final mediaService = MediaPickerService();
      final pickedFile = await mediaService.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // 10 minute limit
      );
      
      if (pickedFile != null && context.mounted) {
        Navigator.of(context).pop();
        onMediaSelected(pickedFile);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to pick video: ${e.toString()}');
      }
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    try {
      final mediaService = MediaPickerService();
      final pickedFile = await mediaService.pickFile(
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf'],
        type: FileType.custom,
      );
      
      if (pickedFile != null && context.mounted) {
        Navigator.of(context).pop();
        onMediaSelected(pickedFile);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to pick document: ${e.toString()}');
      }
    }
  }

  Future<void> _pickAudio(BuildContext context) async {
    try {
      final mediaService = MediaPickerService();
      final pickedFile = await mediaService.pickFile(
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg'],
        type: FileType.custom,
      );
      
      if (pickedFile != null && context.mounted) {
        Navigator.of(context).pop();
        onMediaSelected(pickedFile);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to pick audio: ${e.toString()}');
      }
    }
  }

  Future<void> _pickAnyFile(BuildContext context) async {
    try {
      final mediaService = MediaPickerService();
      final pickedFile = await mediaService.pickFile(
        type: FileType.any,
      );
      
      if (pickedFile != null && context.mounted) {
        Navigator.of(context).pop();
        onMediaSelected(pickedFile);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to pick file: ${e.toString()}');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Static method to show media picker bottom sheet
  static void show(
    BuildContext context, {
    required Function(PickedMediaFile) onMediaSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaPickerBottomSheet(
        onMediaSelected: onMediaSelected,
      ),
    );
  }
}