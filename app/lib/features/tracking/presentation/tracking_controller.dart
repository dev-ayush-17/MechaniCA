import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock.dart';
import '../domain/location_filter.dart';
import '../domain/location_point.dart';
import '../domain/location_tracking_service.dart';
import '../domain/maps_service.dart';
import '../domain/tracking_copy.dart';
import '../domain/tracking_link_api.dart';

class TrackingArgs {
  const TrackingArgs({
    required this.bookingId,
    this.status = 'enRoute',
    this.urgency = 'normal',
    this.destLat = 25.5941,
    this.destLng = 85.1376,
    this.mechanicName = 'Rakesh',
    this.vehicleLabel = 'Hero Splendor',
    this.role = 'customer',
  });

  final String bookingId;
  final String status;
  final String urgency;
  final double destLat;
  final double destLng;
  final String mechanicName;
  final String vehicleLabel;
  final String role;

  @override
  bool operator ==(Object other) =>
      other is TrackingArgs &&
      other.bookingId == bookingId &&
      other.status == status &&
      other.urgency == urgency &&
      other.role == role;

  @override
  int get hashCode => Object.hash(bookingId, status, urgency, role);
}

class TrackingUiState {
  const TrackingUiState({
    this.distanceText = '',
    this.etaText = '',
    this.staleLabel,
    this.showTrouble = false,
    this.suggestArrived = false,
    this.shareLocation = false,
    this.sharePath,
    this.pinGrey = false,
    this.error,
  });

  final String distanceText;
  final String etaText;
  final String? staleLabel;
  final bool showTrouble;
  final bool suggestArrived;
  final bool shareLocation;
  final String? sharePath;
  final bool pinGrey;
  final String? error;

  TrackingUiState copyWith({
    String? distanceText,
    String? etaText,
    String? staleLabel,
    bool clearStale = false,
    bool? showTrouble,
    bool? suggestArrived,
    bool? shareLocation,
    String? sharePath,
    bool? pinGrey,
    String? error,
    bool clearError = false,
  }) {
    return TrackingUiState(
      distanceText: distanceText ?? this.distanceText,
      etaText: etaText ?? this.etaText,
      staleLabel: clearStale ? null : (staleLabel ?? this.staleLabel),
      showTrouble: showTrouble ?? this.showTrouble,
      suggestArrived: suggestArrived ?? this.suggestArrived,
      shareLocation: shareLocation ?? this.shareLocation,
      sharePath: sharePath ?? this.sharePath,
      pinGrey: pinGrey ?? this.pinGrey,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TrackingController extends StateNotifier<TrackingUiState> {
  TrackingController({
    required this.bookingId,
    required this.status,
    required this.urgency,
    required this.destLat,
    required this.destLng,
    required LocationTrackingService locations,
    required MapsService maps,
    required Clock clock,
    required TrackingLinkApi links,
  })  : _locations = locations,
        _maps = maps,
        _clock = clock,
        _links = links,
        super(TrackingUiState(shareLocation: urgency == 'sos')) {
    _sub = _locations.watch(bookingId).listen(_onSnapshot);
  }

  final String bookingId;
  final String status;
  final String urgency;
  final double destLat;
  final double destLng;
  final LocationTrackingService _locations;
  final MapsService _maps;
  final Clock _clock;
  final TrackingLinkApi _links;
  StreamSubscription<LocationSnapshot>? _sub;
  RouteSummary? _lastRoute;
  DateTime? _lastRouteAt;

  Future<void> _onSnapshot(LocationSnapshot snapshot) async {
    final point = snapshot.mechanic;
    final now = _clock.now();
    if (point == null) {
      state = state.copyWith(
        etaText: kEtaUnavailable,
        showTrouble: status == 'enRoute',
      );
      return;
    }
    final stale = isStale(point, now);
    final trouble =
        status == 'enRoute' && now.difference(point.recordedAt) > troubleAfter;
    state = state.copyWith(
      staleLabel: stale ? lastSeenLabel(point, now) : null,
      clearStale: !stale,
      pinGrey: stale,
      showTrouble: trouble,
      suggestArrived: withinGeofence(point, destLat, destLng),
    );
    if (!stale) {
      await _refreshRoute(point, now);
    }
  }

  Future<void> _refreshRoute(LocationPoint point, DateTime now) async {
    final result = await _maps.route(
      originLat: point.lat,
      originLng: point.lng,
      destLat: destLat,
      destLng: destLng,
    );
    result.when(
      onOk: (summary) {
        _lastRoute = summary;
        _lastRouteAt = now;
        state = state.copyWith(
          distanceText: summary.distanceText,
          etaText: summary.etaText,
        );
      },
      onErr: (_) {
        final last = _lastRoute;
        final at = _lastRouteAt;
        if (last != null &&
            at != null &&
            now.difference(at) < const Duration(minutes: 5)) {
          state = state.copyWith(
            distanceText: last.distanceText,
            etaText: last.etaText,
          );
        } else {
          state = state.copyWith(etaText: kEtaUnavailable);
        }
      },
    );
  }

  void setShareLocation(bool value) {
    state = state.copyWith(shareLocation: value);
  }

  Future<void> shareLink() async {
    final result = await _links.create(bookingId);
    result.when(
      onOk: (link) => state = state.copyWith(sharePath: link.path, clearError: true),
      onErr: (f) => state = state.copyWith(error: f.message),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
