import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../composition/providers.dart';
import '../../../core/error/result.dart';
import '../../mechanic_jobs/domain/job_offer.dart';
import 'mechanic_controller.dart';

class MechanicSessionState {
  const MechanicSessionState({
    this.pendingOfferId,
    this.pollError,
    this.heartbeats = 0,
  });

  final String? pendingOfferId;
  final String? pollError;
  final int heartbeats;

  MechanicSessionState copyWith({
    String? pendingOfferId,
    bool clearOffer = false,
    String? pollError,
    bool clearError = false,
    int? heartbeats,
  }) {
    return MechanicSessionState(
      pendingOfferId: clearOffer ? null : (pendingOfferId ?? this.pendingOfferId),
      pollError: clearError ? null : (pollError ?? this.pollError),
      heartbeats: heartbeats ?? this.heartbeats,
    );
  }
}

/// Heartbeats and offer polls while the mechanic is online, including on job screens.
class MechanicSessionTicker extends StateNotifier<MechanicSessionState> {
  MechanicSessionTicker({
    required this.heartbeat,
    required this.isOnline,
    required this.getOpen,
    this.interval = const Duration(seconds: 4),
  }) : super(const MechanicSessionState());

  final Future<bool> Function() heartbeat;
  final bool Function() isOnline;
  final Future<Result<JobOffer>> Function() getOpen;
  final Duration interval;

  Timer? _timer;
  int _ticks = 0;
  bool _inFlight = false;

  void start() {
    _timer ??= Timer.periodic(interval, (_) => tick());
  }

  void consumeOffer() {
    state = state.copyWith(clearOffer: true);
  }

  Future<void> tick() async {
    if (!isOnline() || _inFlight) return;
    _inFlight = true;
    _ticks += 1;
    try {
      if (_ticks == 1 || _ticks % 5 == 0) {
        await heartbeat();
        state = state.copyWith(heartbeats: state.heartbeats + 1);
      }
      final offer = await getOpen();
      offer.when(
        onOk: (job) {
          if (state.pendingOfferId == job.id) {
            state = state.copyWith(clearError: true);
            return;
          }
          state = state.copyWith(pendingOfferId: job.id, clearError: true);
        },
        onErr: (failure) {
          if (failure is NotFound) {
            state = state.copyWith(clearError: true);
            return;
          }
          state = state.copyWith(pollError: failure.message);
        },
      );
    } finally {
      _inFlight = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final mechanicSessionTickerProvider =
    StateNotifierProvider<MechanicSessionTicker, MechanicSessionState>((ref) {
  final ticker = MechanicSessionTicker(
    heartbeat: () => ref.read(mechanicProvider.notifier).heartbeat(),
    isOnline: () => ref.read(mechanicProvider).profile?.online == true,
    getOpen: () => ref.read(offerApiProvider).getOpen(),
  );
  ticker.start();
  return ticker;
});
