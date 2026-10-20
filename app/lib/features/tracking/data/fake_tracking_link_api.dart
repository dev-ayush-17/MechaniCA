import '../../../core/error/result.dart';
import '../domain/tracking_link_api.dart';

class FakeTrackingLinkApi implements TrackingLinkApi {
  FakeTrackingLinkApi({this.fail = false});

  bool fail;
  String? lastBookingId;

  @override
  Future<Result<TrackingLink>> create(String bookingId) async {
    if (fail) return const Err(Unavailable());
    lastBookingId = bookingId;
    return Ok(
      TrackingLink(
        token: 'demo-token',
        path: '/v1/public/tracking/demo-token',
        expiresAt: DateTime.utc(2026, 6, 1, 16),
      ),
    );
  }
}
