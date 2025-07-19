import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'logging_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  Future<bool> downloadFile(String url, String? fileName) async {
    try {
      // Request storage permission
      if (!kIsWeb && Platform.isAndroid) {
        final permission = await Permission.storage.request();
        if (!permission.isGranted) {
          LoggingService.error('Storage permission denied');
          return false;
        }
      }

      // Download the file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        LoggingService.error('Failed to download file: ${response.statusCode}');
        return false;
      }

      // Get the directory to save the file
      Directory? directory;
      if (kIsWeb) {
        // For web, we can't actually save files to local storage
        // This would typically trigger a browser download
                 LoggingService.info('Web download not implemented');
        return false;
      } else if (Platform.isAndroid || Platform.isIOS) {
        directory ??= await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Create the file
      final file = File('${directory.path}/${fileName ?? 'download'}');
      await file.writeAsBytes(response.bodyBytes);

             LoggingService.info('File downloaded successfully: ${file.path}');
      return true;
    } catch (e) {
      LoggingService.error('Error downloading file: $e');
      return false;
    }
  }
}