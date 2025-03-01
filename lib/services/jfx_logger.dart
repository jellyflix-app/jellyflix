import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:file_saver/file_saver.dart';

class JfxLogger {
  late Logger _logger;
  static const _logFileName = "jellyflix-log";
  static const _logFileExtension = ".txt";
  final MemoryOutput _memoryOutput = MemoryOutput();

  JfxLogger() {
    buildLogger();
  }

  void buildLogger({bool alwaysLog = false}) {
    if (kDebugMode) {
      _logger = Logger(
        printer: LogfmtPrinter(),
      );
    } else {
      _logger = Logger(
        printer: LogfmtPrinter(),
        output: _memoryOutput,
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

  void error(String message, {dynamic error}) {
    _logger.e(message, error: error);
  }

  void warning(String message) {
    _logger.w(message);
  }

  void debug(String message) {
    _logger.d(message);
  }

  void verbose(String message) {
    _logger.t(message);
  }

  void critical(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  Future<void> exportLog() async {
    _logger.i("Exporting log to file");

    var logBytes = Uint8List.fromList(_memoryOutput.toString().codeUnits);
    await FileSaver.instance.saveFile(
        name:
            "${_logFileName}_${DateTime.now().toIso8601String().replaceAll(":", "-")}$_logFileExtension",
        bytes: logBytes);
  }
}
