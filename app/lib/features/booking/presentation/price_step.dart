import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../../vehicles/domain/vehicle.dart';
import '../domain/pricing.dart';

class PriceStep extends ConsumerStatefulWidget {
  const PriceStep({super.key, required this.onConfirm, this.quote});

  /// Null means success. A message is shown on the step and the draft stays.
  final Future<String?> Function() onConfirm;
  final PriceQuote? quote;

  @override
  ConsumerState<PriceStep> createState() => _PriceStepState();
}

class _PriceStepState extends ConsumerState<PriceStep> {
  bool _isLoading = false;
  bool _quoteLoading = true;
  PriceQuote? _quote;
  String? _quoteError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    if (widget.quote != null) {
      _quote = widget.quote;
      _quoteLoading = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuote());
    }
  }

  Future<void> _loadQuote() async {
    final flow = ref.read(bookingFlowProvider);
    final service = flow.selectedService;
    if (service == null) {
      setState(() {
        _quoteLoading = false;
        _quoteError = 'Pick a service first.';
      });
      return;
    }
    final result = await ref.read(quoteApiProvider).quote(
          serviceCode: service.id,
          vehicleId: flow.selectedBike?.id ?? '',
          vehicleType: VehicleType.twoWheeler,
          couponCode: flow.couponCode ?? '',
        );
    if (!mounted) return;
    result.when(
      onOk: (quote) => setState(() {
        _quote = quote;
        _quoteError = null;
        _quoteLoading = false;
      }),
      onErr: (failure) => setState(() {
        _quoteError = failure.message;
        _quoteLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(bookingFlowProvider);
    final quote = _quote;

    final methods = [
      ('UPI', Icons.qr_code_rounded),
      ('Card', Icons.credit_card_rounded),
      ('Net Banking', Icons.account_balance_outlined),
      ('Wallet', Icons.account_balance_wallet_outlined),
      ('Cash After Service', Icons.money_rounded),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10nOf(context).priceEstimate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _quoteBody(quote),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...methods.map((m) {
                  final selected = flow.paymentMethod == m.$1;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(bookingFlowProvider.notifier).setPaymentMethod(m.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? AppColors.primaryRed : AppColors.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            m.$2,
                            size: 22,
                            color: selected
                                ? AppColors.primaryRed
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            m.$1,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const Spacer(),
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primaryRed,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_confirmError != null) ...[
                Text(
                  _confirmError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
              AppButton(
                key: const ValueKey('pay-confirm'),
                label: quote == null
                    ? l10nOf(context).pay
                    : l10nOf(context).payAmount(formatPaise(quote.totalPaise)),
                isLoading: _isLoading,
                onPressed: quote == null
                    ? null
                    : () async {
                        if (!ref.read(networkOnlineProvider)) {
                          setState(() => _confirmError = l10nOf(context).connectToBook);
                          return;
                        }
                        setState(() {
                          _isLoading = true;
                          _confirmError = null;
                        });
                        final error = await widget.onConfirm();
                        if (!mounted) return;
                        setState(() {
                          _isLoading = false;
                          _confirmError = error;
                        });
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quoteBody(PriceQuote? quote) {
    if (_quoteLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_quoteError != null) {
      return Text(
        _quoteError!,
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      );
    }
    if (quote == null) {
      return const Text(
        'Estimate unavailable.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    final l10n = l10nOf(context);
    return Column(
      children: [
        _priceRow(l10n.labor, formatPaise(quote.laborPaise)),
        _priceRow(l10n.convenienceFee, formatPaise(quote.feePaise)),
        _priceRow(
          l10n.gst,
          formatPaise(quote.gstPaise),
          color: AppColors.textSecondary,
        ),
        const Divider(color: AppColors.divider, height: 24),
        _priceRow(l10n.totalAmount, formatPaise(quote.totalPaise), bold: true),
      ],
    );
  }
}

Widget _priceRow(String label, String value, {Color? color, bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
