import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  crash,
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.stackTrace,
    this.metadata,
  });

  String get formattedTime => DateFormat('HH:mm:ss.SSS').format(timestamp);
  String get formattedDate => DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'tag': tag,
      'message': message,
      'stackTrace': stackTrace,
      'metadata': metadata,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      level: LogLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      tag: json['tag'] as String? ?? 'APP',
      message: json['message'] as String? ?? '',
      stackTrace: json['stackTrace'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('[$formattedTime] [${level.name.toUpperCase()}] [$tag] $message');
    if (stackTrace != null && stackTrace!.isNotEmpty) {
      buffer.write('\nStackTrace:\n$stackTrace');
    }
    return buffer.toString();
  }
}

class AppLogService {
  static final AppLogService instance = AppLogService._internal();
  AppLogService._internal();

  static const String _keyPersistentLogs = 'oly_persistent_crash_logs_v1';
  static const int _maxInMemoryLogs = 250;
  static const int _maxPersistentLogs = 50;

  final List<LogEntry> _logs = [];
  SharedPreferences? _prefs;
  final _logStreamController = StreamController<LogEntry>.broadcast();

  Stream<LogEntry> get logStream => _logStreamController.stream;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  List<LogEntry> get crashAndErrorLogs =>
      _logs.where((l) => l.level == LogLevel.crash || l.level == LogLevel.error).toList();

  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    _loadPersistentLogs();
  }

  void _loadPersistentLogs() {
    if (_prefs == null) return;
    try {
      final jsonStr = _prefs!.getString(_keyPersistentLogs);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        for (final item in list) {
          _logs.add(LogEntry.fromJson(item as Map<String, dynamic>));
        }
        _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (_) {}
  }

  Future<void> _savePersistentLogs() async {
    if (_prefs == null) return;
    try {
      final persistent = _logs
          .where((l) => l.level == LogLevel.crash || l.level == LogLevel.error || l.level == LogLevel.warning)
          .take(_maxPersistentLogs)
          .map((l) => l.toJson())
          .toList();
      await _prefs!.setString(_keyPersistentLogs, jsonEncode(persistent));
    } catch (_) {}
  }

  void _addLog(LogEntry entry) {
    _logs.insert(0, entry);
    if (_logs.length > _maxInMemoryLogs) {
      _logs.removeRange(_maxInMemoryLogs, _logs.length);
    }
    _logStreamController.add(entry);

    // Print to console in debug mode
    if (kDebugMode) {
      debugPrint(entry.toString());
    }

    if (entry.level == LogLevel.crash || entry.level == LogLevel.error) {
      _savePersistentLogs();
    }
  }

  void debug(String tag, String message, {Map<String, dynamic>? meta}) {
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.debug,
      tag: tag,
      message: message,
      metadata: meta,
    ));
  }

  void info(String tag, String message, {Map<String, dynamic>? meta}) {
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      tag: tag,
      message: message,
      metadata: meta,
    ));
  }

  void warning(String tag, String message, {String? stackTrace, Map<String, dynamic>? meta}) {
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.warning,
      tag: tag,
      message: message,
      stackTrace: stackTrace,
      metadata: meta,
    ));
  }

  void error(String tag, String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? meta}) {
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.error,
      tag: tag,
      message: '$message${error != null ? ' | Error: $error' : ''}',
      stackTrace: stackTrace?.toString(),
      metadata: meta,
    ));
  }

  void crash(String tag, dynamic exception, {StackTrace? stackTrace, Map<String, dynamic>? meta}) {
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.crash,
      tag: tag,
      message: 'CRASH/UNCAUGHT: $exception',
      stackTrace: stackTrace?.toString(),
      metadata: meta,
    ));
  }

  Future<void> clearLogs() async {
    _logs.clear();
    if (_prefs != null) {
      await _prefs!.remove(_keyPersistentLogs);
    }
  }

  String exportFullLogsText() {
    final buffer = StringBuffer();
    buffer.writeln('====================================');
    buffer.writeln('OLY SYSTEM DIAGNOSTICS & CRASH REPORT');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Log Entries: ${_logs.length}');
    buffer.writeln('Total Crashes/Errors: ${crashAndErrorLogs.length}');
    buffer.writeln('====================================\n');

    for (final log in _logs) {
      buffer.writeln(log.toString());
      buffer.writeln('------------------------------------');
    }

    return buffer.toString();
  }
}
