/// Holds a notification deep link for 15 minutes if the user is signed out.
class PendingDeepLinkStore {
  String? _path;
  DateTime? _storedAt;

  static const ttl = Duration(minutes: 15);

  void store(String path, DateTime now) {
    _path = path;
    _storedAt = now;
  }

  String? consume(DateTime now) {
    final path = _path;
    final storedAt = _storedAt;
    _path = null;
    _storedAt = null;
    if (path == null || storedAt == null) return null;
    if (now.difference(storedAt) > ttl) return null;
    return path;
  }
}
