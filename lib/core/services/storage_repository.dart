import 'dart:io';
import 'dart:typed_data';

/// Abstract repository for file storage operations
abstract class StorageRepository {
  /// Upload a file to storage and return the download URL
  Future<String> uploadFile({
    required String path,
    required File file,
    String? fileName,
  });

  /// Upload bytes to storage and return the download URL
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  });

  /// Delete a file from storage
  Future<void> deleteFile(String url);

  /// Get download URL for a file path
  Future<String> getDownloadUrl(String path);

  /// Check if file exists at path
  Future<bool> fileExists(String path);
}