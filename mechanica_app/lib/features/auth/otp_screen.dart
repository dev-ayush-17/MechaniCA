import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared/app_widgets.dart';

class OTPScreen extends ConsumerStatefulWidget {
  final String phone;
  const OTPScreen({super.key, required this.phone});
  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final _otpCtrl = TextEditingController();
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final success = await ref.read(authProvider.notifier).verifyOtp(widget.phone, _otpCtrl.text);
    if (success && mounted) context.go(RouteNames.locationPermission);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final defaultPinTheme = PinTheme(
      width: 54,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Verify OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text('Enter OTP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                text: 'We sent a 6-digit code to ',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                children: [
                  TextSpan(
                    text: widget.phone,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Use 123456 for demo', style: TextStyle(color: AppColors.primaryRed, fontSize: 12)),
            const SizedBox(height: 40),
            Center(
              child: Pinput(
                controller: _otpCtrl,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.primaryRed, width: 2),
                  ),
                ),
                onCompleted: (_) => _verify(),
              ),
            ),
            const SizedBox(height: 32),
            if (authState.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Text(authState.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Verify OTP',
              isLoading: authState.isLoading,
              onPressed: _verify,
            ),
            const SizedBox(height: 24),
            Center(
              child: _secondsLeft > 0
                  ? Text(
                      'Resend OTP in ${_secondsLeft}s',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    )
                  : TextButton(
                      onPressed: () {
                        setState(() => _secondsLeft = 60);
                        _startTimer();
                        ref.read(authProvider.notifier).sendOtp(widget.phone);
                      },
                      child: const Text('Resend OTP', style: TextStyle(color: AppColors.primaryRed)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
