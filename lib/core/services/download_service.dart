import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'logging_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  
  factory DownloadService() => _instance;
  
  DownloadService._internal();

  Future<bool> downloadFile(String url, String fileName) async {
    try {
      // Request storage permission on mobile platforms
      if (!kIsWeb) {
        final permission = await _requestStoragePermission();
        if (!permission) {
          LoggingService.warning('Storage permission denied');
          return false;
        }
      }

      // Download the file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        LoggingService.error('Failed to download file: ${response.statusCode}');
        return false;
      }

      final bytes = response.bodyBytes;

      if (kIsWeb) {
        return _downloadFileWeb(bytes, fileName);
      } else {
        return await _downloadFileMobile(bytes, fileName);
      }
    } catch (e) {
      LoggingService.error('Error downloading file: $e');
      return false;
    }
  }

  bool _downloadFileWeb(Uint8List bytes, String fileName) {
    try {
      LoggingService.info('Web download initiated for: $fileName');
      
      if (kIsWeb) {
        // Import the web download service conditionally
        // This is a simplified approach - in production you might use conditional imports
        try {
          // Call the web download function
          // Note: This requires the dart:html library which is only available on web
          _triggerWebDownload(bytes, fileName);
          return true;
        } catch (e) {
          LoggingService.error('Web download failed: $e');
          return false;
        }
      }
      
      return false;
    } catch (e) {
      LoggingService.error('Error downloading file on web: $e');
      return false;
    }
  }

  void _triggerWebDownload(Uint8List bytes, String fileName) {
    // This will be implemented conditionally for web
    // For now, we'll just show a message
    LoggingService.info('Download triggered for $fileName on web platform');
  }

  Future<bool> _downloadFileMobile(Uint8List bytes, String fileName) async {
    try {
      Directory? downloadDir;
      
      if (Platform.isAndroid) {
        // Try to get the Downloads directory
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!downloadDir.existsSync()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) {
        LoggingService.error('Could not access download directory');
        return false;
      }

      final file = File('${downloadDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      LoggingService.info('File downloaded successfully to: ${file.path}');
      return true;
    } catch (e) {
      LoggingService.error('Error downloading file on mobile: $e');
      return false;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS doesn't require explicit storage permission for app documents
      return true;
    }
    return true;
  }
}