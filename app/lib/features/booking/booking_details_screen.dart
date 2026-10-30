import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../composition/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../models/booking_model.dart';
import '../../navigation/route_names.dart';
import '../../widgets/shared/app_widgets.dart';
import '../tracking/presentation/tracking_controller.dart';
import 'domain/booking.dart';
import 'domain/pricing.dart';
import 'presentation/cancel_booking_sheet.dart';
import 'presentation/dispatch_status_copy.dart';

/// Live booking from the API. Status stays "Finding a mechanic" until Accept.
class BookingDetailsScreen extends ConsumerStatefulWidget {
  const BookingDetailsScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  Booking? _booking;
  String? _error;
  Timer? _poll;
  bool _inFlight = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Duration _intervalFor(Booking? booking) {
    final status = booking?.status;
    if (status == BookingStatus.confirmed ||
        status == BookingStatus.failed ||
        status == BookingStatus.requested ||
        status == null) {
      return const Duration(seconds: 3);
    }
    return const Duration(seconds: 12);
  }

  bool _shouldKeepPolling(Booking booking) {
    return switch (booking.status) {
      BookingStatus.paid ||
      BookingStatus.cancelled ||
      BookingStatus.disputed =>
        false,
      _ => true,
    };
  }

  void _schedule(Duration delay) {
    _poll?.cancel();
    _poll = Timer(delay, _load);
  }

  Future<void> _load() async {
    if (_inFlight) {
      _schedule(_intervalFor(_booking));
      return;
    }
    _inFlight = true;
    final result = await ref.read(bookingApiProvider).get(widget.bookingId);
    _inFlight = false;
    if (!mounted) return;
    result.when(
      onOk: (found) {
        final previous = _booking;
        final unchanged = previous != null &&
            previous.status == found.status &&
            previous.version == found.version;
        if (!unchanged) {
          setState(() {
            _booking = found;
            _error = null;
          });
        }
        if (_shouldKeepPolling(found)) {
          _schedule(_intervalFor(found));
        } else {
          _poll?.cancel();
        }
      },
      onErr: (failure) {
        setState(() => _error = failure.message);
        _schedule(_intervalFor(_booking));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
        leading: IconButton(
          tooltip: l10nOf(context).back,
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (booking != null && booking.status.canCancel)
            TextButton(
              onPressed: () => _cancel(booking),
              child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: booking == null
          ? Center(
              child: Text(
                _error ?? 'Loading booking…',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : _body(booking),
    );
  }

  Widget _body(Booking booking) {
    final assigned = booking.status == BookingStatus.mechanicAssigned ||
        booking.status == BookingStatus.enRoute ||
        booking.status == BookingStatus.arrived ||
        booking.status == BookingStatus.inService ||
        booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.paid;
    final rating = booking.mechanicRatingCount >= 5
        ? (booking.mechanicRatingAvg?.toStringAsFixed(1) ?? '')
        : 'New';
    final paid = booking.status == BookingStatus.paid;
    final l10n = l10nOf(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          booking.serviceName.isEmpty ? booking.serviceCode : booking.serviceName,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(booking.status.label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        if (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.failed) ...[
          const SizedBox(height: 8),
          DispatchStatusCopy(
            status: booking.status,
            attempt: booking.dispatchAttempt,
            sos: booking.urgency == 'sos',
          ),
        ],
        const SizedBox(height: 16),
        _card('Receipt', [
          _row('Booking', booking.displayNumber),
          _row('Total', formatPaise(booking.totalPaise)),
          _row(
            'Payment',
            paid ? l10n.paid : l10n.payAfterTheVisit,
          ),
          if (booking.cancelFeePaise > 0) _row('Cancel fee', formatPaise(booking.cancelFeePaise)),
        ]),
        if (assigned) ...[
          const SizedBox(height: 12),
          _card('Mechanic', [
            _row('Name', booking.mechanicName?.isNotEmpty == true ? booking.mechanicName! : 'Assigned'),
            _row('Rating', rating),
          ]),
          const SizedBox(height: 12),
          AppButton(
            label: 'Chat',
            isOutlined: true,
            icon: Icons.chat_bubble_outline_rounded,
            onPressed: () => context.push(RouteNames.jobChat, extra: booking.id),
          ),
        ],
        if (booking.status == BookingStatus.mechanicAssigned ||
            booking.status == BookingStatus.enRoute ||
            booking.status == BookingStatus.arrived) ...[
          const SizedBox(height: 12),
          AppButton(
            label: l10n.trackLive,
            icon: Icons.location_on_rounded,
            onPressed: () => context.push(
              RouteNames.liveTracking,
              extra: _trackingArgs(booking),
            ),
          ),
        ],
        if (booking.status == BookingStatus.completed) ...[
          const SizedBox(height: 12),
          const _PayComingSoonBanner(),
        ],
        if (paid) ...[
          const SizedBox(height: 12),
          AppButton(
            label: 'View Invoice',
            icon: Icons.receipt_long_rounded,
            onPressed: () => context.push(RouteNames.invoice, extra: booking.id),
          ),
        ],
        if (booking.status.canReportProblem) ...[
          const SizedBox(height: 12),
          ReportProblemButton(
            onPressed: () => context.push(RouteNames.support),
          ),
        ],
      ],
    );
  }

  TrackingArgs _trackingArgs(Booking booking) {
    var destLat = 25.5941;
    var destLng = 85.1376;
    for (final address in ref.read(addressesControllerProvider).items) {
      if (address.id == booking.addressId) {
        destLat = address.lat;
        destLng = address.lng;
        break;
      }
    }
    return TrackingArgs(
      bookingId: booking.id,
      status: booking.status.name,
      destLat: destLat,
      destLng: destLng,
      mechanicName: booking.mechanicName?.isNotEmpty == true
          ? booking.mechanicName!
          : 'Assigned',
      vehicleLabel: booking.serviceName.isEmpty ? booking.serviceCode : booking.serviceName,
    );
  }

  Future<void> _cancel(Booking booking) async {
    await showCancelBookingSheet(
      context: context,
      status: booking.status,
      onCancel: (reason) async {
        final result = await ref.read(bookingApiProvider).cancel(booking.id, reason: reason);
        if (!mounted) return;
        result.when(
          onOk: (_) => _load(),
          onErr: (failure) => showAppSnackbar(context, failure.message),
        );
      },
    );
  }

  Widget _card(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class ReportProblemButton extends StatelessWidget {
  const ReportProblemButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Report a problem',
      isOutlined: true,
      icon: Icons.report_outlined,
      onPressed: onPressed,
    );
  }
}

class _PayComingSoonBanner extends StatelessWidget {
  const _PayComingSoonBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_clock_outlined, color: AppColors.primaryRed, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Online Payments \u2014 Coming Soon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pay cash directly to your mechanic after the service. Digital payments will be enabled shortly.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
