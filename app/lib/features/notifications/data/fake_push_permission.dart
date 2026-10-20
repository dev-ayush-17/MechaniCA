import '../domain/push_permission.dart';

class FakePushPermission implements PushPermission {
  FakePushPermission({
    this.status = PushPermissionStatus.unknown,
    this.nextStatus = PushPermissionStatus.granted,
  });

  @override
  PushPermissionStatus status;

  PushPermissionStatus nextStatus;
  int requestCount = 0;

  @override
  Future<PushPermissionStatus> requestOnce() async {
    if (requestCount > 0) return status;
    requestCount += 1;
    status = nextStatus;
    return status;
  }
}
