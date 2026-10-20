enum PushPermissionStatus { unknown, granted, denied }

/// OS prompt lives behind this port so widgets never import FCM.
abstract interface class PushPermission {
  PushPermissionStatus get status;

  /// Returns the current status. A second call does not prompt again.
  Future<PushPermissionStatus> requestOnce();
}
