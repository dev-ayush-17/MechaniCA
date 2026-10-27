import 'package:permission_handler/permission_handler.dart';

import '../domain/push_permission.dart';

/// One OS prompt. A second call returns the stored result.
class OsPushPermission implements PushPermission {
  @override
  PushPermissionStatus status = PushPermissionStatus.unknown;

  @override
  Future<PushPermissionStatus> requestOnce() async {
    if (status != PushPermissionStatus.unknown) return status;
    final result = await Permission.notification.request();
    status = result.isGranted
        ? PushPermissionStatus.granted
        : PushPermissionStatus.denied;
    return status;
  }
}
