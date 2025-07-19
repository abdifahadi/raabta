import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'storage_repository.dart';

/// Firebase Storage implementation of StorageRepository
class FirebaseStorageRepository implements StorageRepository {
  static final FirebaseStorageRepository _instance = FirebaseStorageRepository._internal();
  
  factory FirebaseStorageRepository() => _instance;
  
  FirebaseStorageRepository._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<String> uploadFile({
    required String path,
    required File file,
    String? fileName,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Uploading file to path: $path');
      }

      final ref = _storage.ref().child(path);
      
      // Get MIME type
      final mimeType = lookupMimeType(file.path);
      
      // Create metadata
      final metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': fileName ?? file.path.split('/').last,
        },
      );

      // Upload file
      final uploadTask = ref.putFile(file, metadata);
      
      // Monitor upload progress
      if (kDebugMode) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('📊 Upload progress: ${progress.toStringAsFixed(1)}%');
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('✅ File uploaded successfully: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading file: $e');
      }
      throw Exception('Failed to upload file: $e');
    }
  }

  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Uploading bytes to path: $path');
      }

      final ref = _storage.ref().child(path);
      
      // Create metadata
      final metadata = SettableMetadata(
        contentType: mimeType ?? lookupMimeType(fileName),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'fileName': fileName,
        },
      );

      // Upload bytes
      final uploadTask = ref.putData(bytes, metadata);
      
      // Monitor upload progress
      if (kDebugMode) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('📊 Upload progress: ${progress.toStringAsFixed(1)}%');
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('✅ Bytes uploaded successfully: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading bytes: $e');
      }
      throw Exception('Failed to upload bytes: $e');
    }
  }

  @override
  Future<void> deleteFile(String url) async {
    try {
      if (kDebugMode) {
        print('🗑️ Deleting file: $url');
      }

      final ref = _storage.refFromURL(url);
      await ref.delete();

      if (kDebugMode) {
        print('✅ File deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting file: $e');
      }
      throw Exception('Failed to delete file: $e');
    }
  }

  @override
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting download URL: $e');
      }
      throw Exception('Failed to get download URL: $e');
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate a unique file path for chat media
  String generateChatMediaPath({
    required String conversationId,
    required String messageId,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'chat_media/$conversationId/$messageId/${timestamp}_$fileName';
  }

  /// Generate a unique file path for profile pictures
  String generateProfilePicturePath({
    required String userId,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    return 'profile_pictures/$userId/${timestamp}_profile.$extension';
  }

  /// Get file info from Firebase Storage
  Future<Map<String, dynamic>?> getFileInfo(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      final metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'createdAt': metadata.timeCreated?.toIso8601String(),
        'updatedAt': metadata.updated?.toIso8601String(),
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting file info: $e');
      }
      return null;
    }
  }
}