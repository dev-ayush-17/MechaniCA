import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/features/mechanic_jobs/domain/job_offer.dart';
import 'package:mechupp_app/features/mechanic_onboarding/presentation/mechanic_session_ticker.dart';

void main() {
  final offer = JobOffer(
    id: 'off-1',
    bookingId: 'b1',
    serviceName: 'General Service',
    vehicleType: 'two_wheeler',
    distanceKm: 1,
    totalPaise: 10000,
    expiresAt: DateTime.utc(2026, 10, 26, 12),
    attempt: 1,
  );

  test('heartbeat_continues_after_offer_is_consumed', () async {
    var beats = 0;
    final ticker = MechanicSessionTicker(
      heartbeat: () async {
        beats += 1;
        return true;
      },
      isOnline: () => true,
      getOpen: () async => Ok(offer),
    );

    await ticker.tick();
    expect(ticker.state.heartbeats, 1);
    expect(ticker.state.pendingOfferId, 'off-1');

    ticker.consumeOffer();
    expect(ticker.state.pendingOfferId, isNull);

    await ticker.tick();
    await ticker.tick();
    await ticker.tick();
    await ticker.tick();
    expect(beats, greaterThanOrEqualTo(2));
    ticker.dispose();
  });

  test('not_found_is_not_a_poll_error', () async {
    final ticker = MechanicSessionTicker(
      heartbeat: () async => true,
      isOnline: () => true,
      getOpen: () async => const Err(NotFound('No open offer.')),
    );

    await ticker.tick();
    expect(ticker.state.pollError, isNull);
    ticker.dispose();
  });

  test('network_failure_is_surfaced', () async {
    final ticker = MechanicSessionTicker(
      heartbeat: () async => true,
      isOnline: () => true,
      getOpen: () async => const Err(Unavailable('offline')),
    );

    await ticker.tick();
    expect(ticker.state.pollError, 'offline');
    ticker.dispose();
  });
}
