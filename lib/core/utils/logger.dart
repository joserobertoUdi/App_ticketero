class AppLogger {
  AppLogger._();

  static void info(String component, String message, {Map<String, dynamic>? context}) {
    _log('INFO', component, message, context);
  }

  static void warn(String component, String message, {Map<String, dynamic>? context}) {
    _log('WARN', component, message, context);
  }

  static void error(String component, String message, {dynamic exception, Map<String, dynamic>? context}) {
    _log('ERROR', component, message, context);
    if (exception != null) {
      print('  Exception: $exception');
    }
  }

  static void _log(String level, String component, String message, Map<String, dynamic>? context) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' | $context' : '';
    print('$timestamp | $level | $component | $message$contextStr');
  }
}
