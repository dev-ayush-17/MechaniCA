import 'dart:developer' as developer;

/// Keys that must never reach a log line (docs/prd/08-port-catalog.md).
const Set<String> sensitiveLogKeys = {
  'otp',
  'token',
  'authorization',
  'card',
  'secret',
  'password',
  'cvv',
  'idtoken',
};

/// Returns a copy of [fields] without sensitive keys.
Map<String, Object?> redactFields(Map<String, Object?> fields) => {
      for (final entry in fields.entries)
        if (!sensitiveLogKeys.contains(entry.key.toLowerCase()))
          entry.key: entry.value,
    };

abstract interface class Logger {
  void info(String message, [Map<String, Object?> fields = const {}]);
  void warning(String message, [Map<String, Object?> fields = const {}]);
  void error(
    String message, [
    Map<String, Object?> fields = const {},
    Object? error,
  ]);
}

/// Writes to the developer log. Release builds will swap in a crash adapter in M16.
class DeveloperLogger implements Logger {
  const DeveloperLogger();

  @override
  void info(String message, [Map<String, Object?> fields = const {}]) =>
      developer.log(message, name: 'mechupp', level: 800, error: _tail(fields));

  @override
  void warning(String message, [Map<String, Object?> fields = const {}]) =>
      developer.log(message, name: 'mechupp', level: 900, error: _tail(fields));

  @override
  void error(
    String message, [
    Map<String, Object?> fields = const {},
    Object? error,
  ]) =>
      developer.log(
        message,
        name: 'mechupp',
        level: 1000,
        error: error ?? _tail(fields),
      );

  Object? _tail(Map<String, Object?> fields) {
    final cleaned = redactFields(fields);
    return cleaned.isEmpty ? null : cleaned;
  }
}

/// Records calls so tests can assert on them.
class RecordingLogger implements Logger {
  final List<({String level, String message, Map<String, Object?> fields})>
      entries = [];

  @override
  void info(String message, [Map<String, Object?> fields = const {}]) =>
      entries.add((level: 'info', message: message, fields: redactFields(fields)));

  @override
  void warning(String message, [Map<String, Object?> fields = const {}]) =>
      entries
          .add((level: 'warning', message: message, fields: redactFields(fields)));

  @override
  void error(
    String message, [
    Map<String, Object?> fields = const {},
    Object? error,
  ]) =>
      entries.add((level: 'error', message: message, fields: redactFields(fields)));
}
