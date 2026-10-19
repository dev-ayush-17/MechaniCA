import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../../vehicles/domain/vehicle.dart';

/// Quote-time coupon apply. The server message is shown on failure.
class CouponApplyField extends ConsumerStatefulWidget {
  const CouponApplyField({super.key});

  @override
  ConsumerState<CouponApplyField> createState() => _CouponApplyFieldState();
}

class _CouponApplyFieldState extends ConsumerState<CouponApplyField> {
  final _couponCtrl = TextEditingController();
  bool _applied = false;
  bool _checking = false;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_couponCtrl.text.isEmpty) return;
    setState(() => _checking = true);
    final flow = ref.read(bookingFlowProvider);
    final service = flow.selectedService;
    if (service == null) {
      setState(() => _checking = false);
      showAppSnackbar(context, 'Pick a service first.', isError: true);
      return;
    }
    final result = await ref.read(quoteApiProvider).quote(
          serviceCode: service.id,
          vehicleId: flow.selectedBike?.id ?? '',
          vehicleType: VehicleType.twoWheeler,
          couponCode: _couponCtrl.text,
        );
    if (!mounted) return;
    result.when(
      onOk: (quote) {
        final code = _couponCtrl.text.trim().toUpperCase();
        ref.read(bookingFlowProvider.notifier).applyCoupon(
              code,
              quote.discountPaise / 100,
            );
        setState(() {
          _applied = true;
          _checking = false;
        });
        showAppSnackbar(context, 'Coupon applied.');
      },
      onErr: (failure) {
        setState(() => _checking = false);
        showAppSnackbar(context, failure.message, isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Apply Coupon',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                hint: 'Enter coupon code',
                controller: _couponCtrl,
                suffix: _applied
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            AppButton(
              label: _checking ? '' : 'Apply',
              isLoading: _checking,
              onPressed: _applied ? null : _apply,
              height: 54,
            ),
          ],
        ),
      ],
    );
  }
}
