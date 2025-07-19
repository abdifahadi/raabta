import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  late final Logger _logger;
  
  factory LoggingService() {
    return _instance;
  }
  
  LoggingService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: kDebugMode ? Level.debug : Level.info,
    );
  }
  
  static void debug(String message) {
    _instance._logger.d(message);
  }
  
  static void info(String message) {
    _instance._logger.i(message);
  }
  
  static void warning(String message) {
    _instance._logger.w(message);
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.e(message, error: error, stackTrace: stackTrace);
  }
}