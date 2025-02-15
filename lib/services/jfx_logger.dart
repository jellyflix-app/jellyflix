import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:universal_io/io.dart';
import 'package:file_saver/file_saver.dart';

class JfxLogger {
  late Logger _logger;
  static const _logFileName = "jellyflix-log";
  static const _logFileExtension = ".txt";

  JfxLogger() {
    buildLogger();
  }

  void buildLogger({bool alwaysLog = false}) {
    if (kDebugMode) {
      _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 8,
          lineLength: 80,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );
    } else {
      _logger = Logger(
        printer: LogfmtPrinter(),
        output: FileOutput(
          file: File(_logFileName),
          overrideExisting: true,
        ),
        filter: alwaysLog ? ProductionFilter() : null,
      );
    }
  }

  void alwaysLog() {
    buildLogger(alwaysLog: true);
  }

  void resetLogger() {
    buildLogger();
  }

  void info(String message) {
    _logger.i(message);
  }

  void error(String message) {
    _logger.e(message);
  }

  void warning(String message) {
    _logger.w(message);
  }

  void debug(String message) {
    _logger.d(message);
  }

  void verbose(String message, {dynamic error}) {
    _logger.t(message, error: error);
  }

  void critical(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  Future<void> exportLog() async {
    _logger.i("Exporting log to file");

    await FileSaver.instance.saveFile(
        name:
            "${_logFileName}_${DateTime.now().toIso8601String().replaceAll(":", "-")}$_logFileExtension",
        filePath: _logFileName);
  }
}
