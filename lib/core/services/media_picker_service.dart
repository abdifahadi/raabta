import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

/// Media type enum
enum MediaType {
  image,
  video,
  audio,
  document,
  any;
}

/// Media source enum
enum MediaSource {
  camera,
  gallery,
  file;
}

/// Picked media file information
class PickedMediaFile {
  final File? file;
  final Uint8List? bytes;
  final String name;
  final String? extension;
  final int? size;
  final String? mimeType;
  final MediaType type;
  final double? width;
  final double? height;
  final int? duration; // Duration in milliseconds

  PickedMediaFile({
    this.file,
    this.bytes,
    required this.name,
    this.extension,
    this.size,
    this.mimeType,
    required this.type,
    this.width,
    this.height,
    this.duration,
  });

  /// Check if file is an image
  bool get isImage => type == MediaType.image;

  /// Check if file is a video
  bool get isVideo => type == MediaType.video;

  /// Check if file is an audio
  bool get isAudio => type == MediaType.audio;

  /// Check if file is a document
  bool get isDocument => type == MediaType.document;

  /// Get file size in MB
  double? get sizeInMB {
    if (size == null) return null;
    return size! / (1024 * 1024);
  }

  /// Get formatted file size
  String get formattedSize {
    if (size == null) return 'Unknown size';
    
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    
    if (size! >= gb) {
      return '${(size! / gb).toStringAsFixed(1)} GB';
    } else if (size! >= mb) {
      return '${(size! / mb).toStringAsFixed(1)} MB';
    } else if (size! >= kb) {
      return '${(size! / kb).toStringAsFixed(1)} KB';
    } else {
      return '$size B';
    }
  }
}

/// Cross-platform media picker service
class MediaPickerService {
  static final MediaPickerService _instance = MediaPickerService._internal();
  
  factory MediaPickerService() => _instance;
  
  MediaPickerService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<PickedMediaFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      if (kDebugMode) {
        print('📷 Picking image from $source');
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) return null;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        return PickedMediaFile(
          bytes: bytes,
          name: pickedFile.name,
          extension: pickedFile.path.split('.').last,
          size: bytes.length,
          mimeType: pickedFile.mimeType,
          type: MediaType.image,
        );
      } else {
        final file = File(pickedFile.path);
        final stat = await file.stat();
        
        return PickedMediaFile(
          file: file,
          name: pickedFile.name,
          extension: pickedFile.path.split('.').last,
          size: stat.size,
          mimeType: pickedFile.mimeType,
          type: MediaType.image,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image: $e');
      }
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick a video from gallery or camera
  Future<PickedMediaFile?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      if (kDebugMode) {
        print('🎬 Picking video from $source');
      }

      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );

      if (pickedFile == null) return null;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        return PickedMediaFile(
          bytes: bytes,
          name: pickedFile.name,
          extension: pickedFile.path.split('.').last,
          size: bytes.length,
          mimeType: pickedFile.mimeType,
          type: MediaType.video,
        );
      } else {
        final file = File(pickedFile.path);
        final stat = await file.stat();
        
        return PickedMediaFile(
          file: file,
          name: pickedFile.name,
          extension: pickedFile.path.split('.').last,
          size: stat.size,
          mimeType: pickedFile.mimeType,
          type: MediaType.video,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking video: $e');
      }
      throw Exception('Failed to pick video: $e');
    }
  }

  /// Pick any file
  Future<PickedMediaFile?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      if (kDebugMode) {
        print('📎 Picking file of type $type');
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return null;

      final platformFile = result.files.first;

      MediaType mediaType;
      if (platformFile.extension != null) {
        switch (platformFile.extension!.toLowerCase()) {
          case 'jpg':
          case 'jpeg':
          case 'png':
          case 'gif':
          case 'webp':
          case 'bmp':
            mediaType = MediaType.image;
            break;
          case 'mp4':
          case 'avi':
          case 'mov':
          case 'mkv':
          case 'webm':
            mediaType = MediaType.video;
            break;
          case 'mp3':
          case 'wav':
          case 'aac':
          case 'm4a':
          case 'ogg':
            mediaType = MediaType.audio;
            break;
          default:
            mediaType = MediaType.document;
        }
      } else {
        mediaType = MediaType.document;
      }

      if (kIsWeb) {
        return PickedMediaFile(
          bytes: platformFile.bytes,
          name: platformFile.name,
          extension: platformFile.extension,
          size: platformFile.size,
          type: mediaType,
        );
      } else {
        final file = File(platformFile.path!);
        
        return PickedMediaFile(
          file: file,
          name: platformFile.name,
          extension: platformFile.extension,
          size: platformFile.size,
          type: mediaType,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking file: $e');
      }
      throw Exception('Failed to pick file: $e');
    }
  }

  /// Pick multiple files
  Future<List<PickedMediaFile>> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      if (kDebugMode) {
        print('📎 Picking multiple files of type $type');
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return [];

      final List<PickedMediaFile> pickedFiles = [];

      for (final platformFile in result.files) {
        MediaType mediaType;
        if (platformFile.extension != null) {
          switch (platformFile.extension!.toLowerCase()) {
            case 'jpg':
            case 'jpeg':
            case 'png':
            case 'gif':
            case 'webp':
            case 'bmp':
              mediaType = MediaType.image;
              break;
            case 'mp4':
            case 'avi':
            case 'mov':
            case 'mkv':
            case 'webm':
              mediaType = MediaType.video;
              break;
            case 'mp3':
            case 'wav':
            case 'aac':
            case 'm4a':
            case 'ogg':
              mediaType = MediaType.audio;
              break;
            default:
              mediaType = MediaType.document;
          }
        } else {
          mediaType = MediaType.document;
        }

        if (kIsWeb) {
          pickedFiles.add(PickedMediaFile(
            bytes: platformFile.bytes,
            name: platformFile.name,
            extension: platformFile.extension,
            size: platformFile.size,
            type: mediaType,
          ));
        } else {
          final file = File(platformFile.path!);
          
          pickedFiles.add(PickedMediaFile(
            file: file,
            name: platformFile.name,
            extension: platformFile.extension,
            size: platformFile.size,
            type: mediaType,
          ));
        }
      }

      return pickedFiles;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking multiple files: $e');
      }
      throw Exception('Failed to pick multiple files: $e');
    }
  }

  /// Check if file size is within limit (in MB)
  bool isFileSizeValid(PickedMediaFile file, double maxSizeMB) {
    if (file.sizeInMB == null) return true;
    return file.sizeInMB! <= maxSizeMB;
  }

  /// Get file size limit based on type
  double getFileSizeLimit(MediaType type) {
    switch (type) {
      case MediaType.image:
        return 10.0; // 10 MB
      case MediaType.video:
        return 100.0; // 100 MB
      case MediaType.audio:
        return 25.0; // 25 MB
      case MediaType.document:
        return 50.0; // 50 MB
      case MediaType.any:
        return 100.0; // 100 MB
    }
  }

  /// Pick a single media file from the specified source
  Future<PickedMediaFile?> pickSingleMedia({
    required MediaSource source,
    MediaType type = MediaType.image,
  }) async {
    switch (source) {
      case MediaSource.camera:
        if (type == MediaType.image) {
          return await pickImage(source: ImageSource.camera);
        } else if (type == MediaType.video) {
          return await pickVideo(source: ImageSource.camera);
        }
        break;
      case MediaSource.gallery:
        if (type == MediaType.image) {
          return await pickImage(source: ImageSource.gallery);
        } else if (type == MediaType.video) {
          return await pickVideo(source: ImageSource.gallery);
        }
        break;
      case MediaSource.file:
        return await pickFile();
    }
    return null;
  }
}