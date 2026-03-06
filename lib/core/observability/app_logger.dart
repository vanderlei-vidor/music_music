import 'package:flutter/foundation.dart';

typedef AppLogListener =
    void Function({
      required String level,
      required String tag,
      required String message,
      Object? error,
      StackTrace? stackTrace,
    });

class AppLogger {
  static AppLogListener? _listener;
  static final List<AppLogEntry> _entries = <AppLogEntry>[];
  static const int _maxEntries = 400;

  static void configure({AppLogListener? listener}) {
    _listener = listener;
  }

  static void info(String tag, String message) {
    _emit(level: 'INFO', tag: tag, message: message);
  }

  static void warn(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emit(
      level: 'WARN',
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emit(
      level: 'ERROR',
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _emit({
    required String level,
    required String tag,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now();
    final timestampText = timestamp.toIso8601String();
    final base = '[$timestampText][$level][$tag] $message';
    debugPrint(base);
    if (error != null) {
      debugPrint('[$timestampText][$level][$tag] error=$error');
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
    _entries.add(
      AppLogEntry(
        timestamp: timestamp,
        level: level,
        tag: tag,
        message: message,
        error: error?.toString(),
        stackTrace: stackTrace?.toString(),
      ),
    );
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
    _listener?.call(
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static List<AppLogEntry> recent({int max = 200}) {
    if (_entries.isEmpty) return const [];
    final count = max.clamp(1, _entries.length);
    return List<AppLogEntry>.unmodifiable(
      _entries.sublist(_entries.length - count, _entries.length),
    );
  }

  static String exportAsText({int max = 200}) {
    final logs = recent(max: max);
    if (logs.isEmpty) return 'No logs captured.';
    final buffer = StringBuffer();
    for (final entry in logs) {
      buffer.writeln(entry.toLine());
      if (entry.error != null && entry.error!.isNotEmpty) {
        buffer.writeln('error=${entry.error}');
      }
      if (entry.stackTrace != null && entry.stackTrace!.isNotEmpty) {
        buffer.writeln(entry.stackTrace);
      }
    }
    return buffer.toString();
  }

  static void clear() {
    _entries.clear();
  }
}

class AppLogEntry {
  final DateTime timestamp;
  final String level;
  final String tag;
  final String message;
  final String? error;
  final String? stackTrace;

  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String toLine() {
    return '[${timestamp.toIso8601String()}][$level][$tag] $message';
  }
}
