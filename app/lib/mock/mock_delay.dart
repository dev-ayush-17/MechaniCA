import 'dart:math';

/// Simulates real API network delays between 500ms and 1200ms
class MockDelay {
  MockDelay._();
  static final _random = Random();

  static Future<void> wait() async {
    final ms = 500 + _random.nextInt(700); // 500–1200ms
    await Future.delayed(Duration(milliseconds: ms));
  }

  static Future<void> short() async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  static Future<void> long() async {
    await Future.delayed(const Duration(milliseconds: 1500));
  }
}
