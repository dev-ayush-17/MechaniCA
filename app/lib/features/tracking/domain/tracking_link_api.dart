import '../../../core/error/result.dart';

class TrackingLink {
  const TrackingLink({
    required this.token,
    required this.path,
    required this.expiresAt,
  });

  final String token;
  final String path;
  final DateTime expiresAt;
}

abstract interface class TrackingLinkApi {
  Future<Result<TrackingLink>> create(String bookingId);
}
