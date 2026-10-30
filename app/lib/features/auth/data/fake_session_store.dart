import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/logger.dart';

/// Where the fake auth keeps its debug session across restarts. It holds only
/// the fake phone number, which derives the fake user id. It never holds a
/// token (docs/prd/11-authentication.md).
abstract interface class FakeSessionStore {
  Future<String?> readPhone();
  Future<void> writePhone(String phoneE164);
  Future<void> clear();
}

class MemoryFakeSessionStore implements FakeSessionStore {
  String? _phone;

  @override
  Future<String?> readPhone() async => _phone;

  @override
  Future<void> writePhone(String phoneE164) async => _phone = phoneE164;

  @override
  Future<void> clear() async => _phone = null;
}

class SharedPrefsFakeSessionStore implements FakeSessionStore {
  SharedPrefsFakeSessionStore(this._logger);

  static const _key = 'debug_fake_session_phone';
  static const _timeout = Duration(seconds: 5);

  final Logger _logger;

  /// Platform storage can be missing (unit tests, unsupported platform). The
  /// fake then behaves as signed out instead of failing the launch.
  Future<T?> _guard<T>(
      Future<T> Function(SharedPreferences prefs) action) async {
    try {
      // Storage must never hold up the launch.
      return await (() async => action(await SharedPreferences.getInstance()))()
          .timeout(_timeout);
    } on TimeoutException {
      _logger.warning('fake session store timed out', const {});
      return null;
    } on MissingPluginException {
      _logger.warning('fake session store unavailable', const {});
      return null;
    } on PlatformException {
      _logger.warning('fake session store failed', const {});
      return null;
    }
  }

  @override
  Future<String?> readPhone() async =>
      _guard<String?>((p) async => p.getString(_key));

  @override
  Future<void> writePhone(String phoneE164) async {
    await _guard((p) => p.setString(_key, phoneE164));
  }

  @override
  Future<void> clear() async {
    await _guard((p) => p.remove(_key));
  }
}
