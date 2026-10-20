import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../composition/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/shared/app_widgets.dart';
import 'domain/location_filter.dart';
import 'domain/tracking_copy.dart';
import 'presentation/tracking_controller.dart';

class LiveTrackingScreen extends ConsumerWidget {
  const LiveTrackingScreen({
    super.key,
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

  TrackingArgs get _args => TrackingArgs(
        bookingId: bookingId,
        status: status,
        urgency: urgency,
        destLat: destLat,
        destLng: destLng,
        mechanicName: mechanicName,
        vehicleLabel: vehicleLabel,
        role: role,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (inServiceOrLater.contains(status)) {
      return ServiceProgressScreen(bookingId: bookingId);
    }
    final tracking = ref.watch(trackingControllerProvider(_args));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => _share(context, ref),
            child: const Text(
              kShareTracking,
              style: TextStyle(color: AppColors.primaryRed, fontSize: 12),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (role == 'mechanic')
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                kForegroundDisclosure,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          if (tracking.showTrouble)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                kTroubleBanner,
                style: TextStyle(color: AppColors.warning, fontSize: 13),
              ),
            ),
          _MapPlaceholder(grey: tracking.pinGrey, staleLabel: tracking.staleLabel),
          const SizedBox(height: 16),
          Text(
            tracking.distanceText.isEmpty ? '' : tracking.distanceText,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            tracking.etaText.isEmpty ? kEtaUnavailable : tracking.etaText,
            style: const TextStyle(color: AppColors.primaryRed, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (tracking.staleLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                tracking.staleLabel!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          const SizedBox(height: 16),
          _JobSummary(mechanicName: mechanicName, vehicleLabel: vehicleLabel, status: status),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(kShareMyLocation, style: TextStyle(color: Colors.white)),
            value: tracking.shareLocation,
            onChanged: (v) =>
                ref.read(trackingControllerProvider(_args).notifier).setShareLocation(v),
          ),
          AppButton(
            label: kDirections,
            icon: Icons.directions_rounded,
            isOutlined: true,
            onPressed: () => launchUrl(
              Uri.parse(
                'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    await ref.read(contactsControllerProvider.notifier).load();
    if (!context.mounted) return;
    final contacts = ref.read(contactsControllerProvider).items;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  kShareWithContacts,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (contacts.isEmpty)
                  const Text(
                    kNoEmergencyContacts,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  )
                else
                  ...contacts.map(
                    (contact) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        contact.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        kShareNoSms,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                AppButton(
                  label: kShareLink,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _shareToken(context, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareToken(BuildContext context, WidgetRef ref) async {
    await ref.read(trackingControllerProvider(_args).notifier).shareLink();
    final path = ref.read(trackingControllerProvider(_args)).sharePath;
    if (path == null || !context.mounted) return;
    final url = '${ref.read(appConfigProvider).apiBaseUrl}$path';
    try {
      await SharePlus.instance.share(ShareParams(text: url));
    } on MissingPluginException {
      await Clipboard.setData(ClipboardData(text: url));
    }
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.grey, this.staleLabel});

  final bool grey;
  final String? staleLabel;

  @override
  Widget build(BuildContext context) {
    final color = grey ? AppColors.textTertiary : AppColors.primaryRed;
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          CustomPaint(painter: _MapGridPainter(), child: const SizedBox.expand()),
          Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const Positioned(
            top: 12,
            left: 12,
            child: Text(
              'LIVE MAP',
              style: TextStyle(
                color: AppColors.primaryRed,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          if (staleLabel != null)
            Positioned(
              bottom: 12,
              left: 12,
              child: Text(
                staleLabel!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _JobSummary extends StatelessWidget {
  const _JobSummary({
    required this.mechanicName,
    required this.vehicleLabel,
    required this.status,
  });

  final String mechanicName;
  final String vehicleLabel;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mechanicName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          Text(vehicleLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(status, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    for (var x = 0.0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class ServiceProgressScreen extends StatelessWidget {
  const ServiceProgressScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service Progress'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Service in progress',
          key: ValueKey(bookingId),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
