import 'package:logger/logger.dart';

/// 日志工具类
class Log {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static final Logger _simpleLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  factory Log() => Log._internal();

  Log._internal();

  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _simpleLogger.d(message, error: error, stackTrace: stackTrace);
  }

  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _simpleLogger.i(message, error: error, stackTrace: stackTrace);
  }

  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void json(dynamic message) {
    _simpleLogger.d(message);
  }
}
