import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../navigation/mechanic_route_names.dart';
import '../domain/job_offer.dart';
import 'offer_screen.dart';

class OfferRouteScreen extends ConsumerStatefulWidget {
  const OfferRouteScreen({super.key, required this.offerId});

  final String offerId;

  @override
  ConsumerState<OfferRouteScreen> createState() => _OfferRouteScreenState();
}

class _OfferRouteScreenState extends ConsumerState<OfferRouteScreen> {
  JobOffer? _offer;
  String? _error;
  bool _busy = false;
  int _secondsLeft = 0;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown(JobOffer offer) {
    _countdown?.cancel();
    setState(() {
      final seconds = offer.expiresAt.difference(DateTime.now()).inSeconds;
      _secondsLeft = seconds < 0 ? 0 : seconds;
    });
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _load() async {
    final result = await ref.read(offerApiProvider).getById(widget.offerId);
    if (!mounted) return;
    result.when(
      onOk: (offer) {
        setState(() => _offer = offer);
        _startCountdown(offer);
      },
      onErr: (failure) => setState(() => _error = failure.message),
    );
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    final result = await ref.read(offerApiProvider).accept(widget.offerId);
    if (!mounted) return;
    result.when(
      onOk: (_) {
        final bookingId = _offer?.bookingId ?? '';
        context.go(MechanicRouteNames.jobPath(bookingId));
      },
      onErr: (failure) => setState(() {
        _busy = false;
        _error = failure.message;
      }),
    );
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    final result = await ref.read(offerApiProvider).reject(widget.offerId);
    if (!mounted) return;
    result.when(
      onOk: (_) => context.go(MechanicRouteNames.jobs),
      onErr: (failure) => setState(() {
        _busy = false;
        _error = failure.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    if (offer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('New job')),
        body: Center(
          child: Text(
            _error ?? 'Loading offer…',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return OfferScreen(
      serviceName: offer.serviceName,
      vehicleType: offer.vehicleType,
      distanceKm: offer.distanceKm,
      totalPaise: offer.totalPaise,
      secondsLeft: _secondsLeft,
      onAccept: _accept,
      onReject: _reject,
      busy: _busy,
      error: _error,
    );
  }
}
