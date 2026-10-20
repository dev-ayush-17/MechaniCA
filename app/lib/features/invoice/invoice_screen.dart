import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../composition/providers.dart';
import '../../core/error/result.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/shared/app_widgets.dart';
import 'domain/invoice.dart';

class InvoiceScreen extends ConsumerWidget {
  final String bookingId;
  const InvoiceScreen({super.key, required this.bookingId});

  Future<void> _export(
    BuildContext context,
    WidgetRef ref, {
    required bool share,
  }) async {
    final result = await ref.read(invoiceApiProvider).downloadPdf(bookingId);
    if (!context.mounted) return;
    switch (result) {
      case Err(:final failure):
        showAppSnackbar(context, failure.message, isError: true);
      case Ok(:final value):
        final path = await ref.read(saveInvoicePdfProvider)(bookingId, value);
        if (!context.mounted) return;
        if (share) {
          await ref.read(shareInvoicePdfProvider)(path);
        } else {
          showAppSnackbar(context, 'Invoice downloaded');
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInvoice = ref.watch(invoiceProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _export(context, ref, share: true),
          ),
        ],
      ),
      body: asyncInvoice.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _InvoiceError(message: error.toString()),
        data: (result) => result.when(
          onOk: (invoice) => _InvoiceBody(
            invoice: invoice,
            onDownload: () => _export(context, ref, share: false),
          ),
          onErr: (failure) => _InvoiceError(message: failure.message),
        ),
      ),
    );
  }
}

class _InvoiceError extends StatelessWidget {
  const _InvoiceError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({required this.invoice, required this.onDownload});

  final Invoice invoice;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy').format(invoice.createdAt.toLocal());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    const Text(
                      'MechUpp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'PAID',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your Bike. Our Responsibility.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                _invRow('Invoice No', invoice.number),
                _invRow('Date', date),
                _invRow('Bike', invoice.vehicleRegistration),
                _invRow('Payment', invoice.paymentMethod),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider),
                ...invoice.lines.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _rupees(item.amountPaise),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: AppColors.divider),
                _sumRow('Subtotal', _rupees(_subtotal(invoice))),
                _sumRow('GST (18%)', _rupees(invoice.gstPaise), color: AppColors.textSecondary),
                const Divider(color: AppColors.divider),
                _sumRow('Total Amount', _rupees(invoice.totalPaise), bold: true),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          const Text(
            '✅ Thank you for trusting MechUpp!',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Download Invoice (PDF)',
            icon: Icons.download_rounded,
            onPressed: onDownload,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

int _subtotal(Invoice invoice) =>
    invoice.lines.fold(0, (sum, line) => sum + line.amountPaise);

String _rupees(int paise) => '₹${paise ~/ 100}';

Widget _invRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

Widget _sumRow(String label, String value, {Color? color, bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
