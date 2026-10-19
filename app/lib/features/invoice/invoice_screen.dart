import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../mock/mock_data.dart';
import '../../widgets/shared/app_widgets.dart';

class InvoiceScreen extends ConsumerWidget {
  final String bookingId;
  const InvoiceScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use mock invoice data
    final invoice = mockInvoices.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoice'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => showAppSnackbar(context, 'Invoice shared!'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.bikeCardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MechaniCA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                        child: const Text('PAID', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Your Bike. Our Responsibility.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 12),
                  _InvRow('Invoice No', invoice.invoiceNumber),
                  _InvRow('Date', '${invoice.date.day} May 2024'),
                  _InvRow('Bike', invoice.bikeNumber),
                  _InvRow('Payment', invoice.paymentMethod),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 16),

            // Items
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Service Details', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider),
                  ...invoice.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                        Text('x${item.quantity}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        const SizedBox(width: 12),
                        Text('₹${item.total.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  )).toList(),
                  const Divider(color: AppColors.divider),
                  _SumRow('Subtotal', '₹${(invoice.serviceCharge + invoice.pickupCharges + invoice.partsCost).toInt()}'),
                  _SumRow('Discount', '-₹${invoice.discount.toStringAsFixed(0)}', color: AppColors.success),
                  _SumRow('GST (18%)', '₹${invoice.gst.toStringAsFixed(0)}', color: AppColors.textSecondary),
                  const Divider(color: AppColors.divider),
                  _SumRow('Total Amount', '₹${invoice.totalAmount.toStringAsFixed(0)}', bold: true),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            const Text(
              '✅ Thank you for trusting MechaniCA!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            AppButton(
              label: 'Download Invoice (PDF)',
              icon: Icons.download_rounded,
              onPressed: () => showAppSnackbar(context, 'Invoice downloaded to Downloads folder'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

Widget _InvRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

Widget _SumRow(String label, String value, {Color? color, bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ],
    ),
  );
}
