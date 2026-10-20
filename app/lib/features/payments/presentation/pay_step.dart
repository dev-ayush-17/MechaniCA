import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../composition/providers.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../domain/payment.dart';

/// Starts a payment and waits for the server. SDK "success" is not paid.
class PayStep extends ConsumerStatefulWidget {
  const PayStep({
    super.key,
    required this.bookingId,
    required this.method,
    this.checkout,
    this.pollInterval = const Duration(seconds: 3),
    this.pollFor = const Duration(minutes: 2),
  });

  final String bookingId;
  final String method;
  final Future<String> Function()? checkout;
  final Duration pollInterval;
  final Duration pollFor;

  @override
  ConsumerState<PayStep> createState() => _PayStepState();
}

class _PayStepState extends ConsumerState<PayStep> {
  bool _busy = false;
  String? _status;
  String? _error;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _error = null;
      _status = null;
    });
    final created = await ref.read(paymentApiProvider).create(
          bookingId: widget.bookingId,
          method: widget.method,
          idempotencyKey: const Uuid().v4(),
        );
    if (!mounted) return;
    switch (created) {
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
        return;
      case Ok(:final value):
        await _afterCreate(value);
    }
  }

  Future<void> _afterCreate(Payment payment) async {
    final checkout = widget.checkout ?? () async => 'success';
    await checkout();
    if (!mounted) return;
    setState(() => _status = l10nOf(context).waitingForConfirmation);
    final deadline = DateTime.now().add(widget.pollFor);
    _poll = Timer.periodic(widget.pollInterval, (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final latest = await ref.read(paymentApiProvider).get(payment.id);
      final paid = latest.when(onOk: (row) => row.isPaid, onErr: (_) => false);
      if (paid) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _status = l10nOf(context).paid;
        });
        return;
      }
      if (DateTime.now().isAfter(deadline)) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _status = l10nOf(context).paymentProcessing;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_status != null) ...[
            Text(
              _status!,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            const SizedBox(height: 12),
          ],
          AppButton(
            key: const ValueKey('pay-button'),
            label: l10nOf(context).pay,
            isLoading: _busy,
            onPressed: _busy ? null : _pay,
          ),
        ],
      ),
    );
  }
}

class PayBookingScreen extends ConsumerWidget {
  const PayBookingScreen({
    super.key,
    required this.bookingId,
    required this.method,
  });

  final String bookingId;
  final String method;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10nOf(context).pay),
        leading: IconButton(
          tooltip: l10nOf(context).back,
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: PayStep(bookingId: bookingId, method: method),
    );
  }
}
