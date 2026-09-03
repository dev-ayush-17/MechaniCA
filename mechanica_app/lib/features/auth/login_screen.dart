import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared/app_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProvider.notifier);
    await auth.sendOtp(_phoneCtrl.text.trim());
    if (mounted) {
      context.push(RouteNames.otp, extra: _phoneCtrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primaryRed.withValues(alpha: 0.2),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.build_circle_rounded, size: 24, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MechUpp', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text('Your Bike. Our Responsibility.', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 48),
                    const Text('Welcome Back!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white))
                        .animate().slideX(begin: -0.2, duration: 500.ms),
                    const SizedBox(height: 8),
                    const Text('Sign in to continue', style: TextStyle(color: AppColors.textSecondary, fontSize: 15))
                        .animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 36),
                    // Phone input
                    const Text('Mobile Number', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    AppTextField(
                      hint: '+91  9206 06199',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefix: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('+91', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 10) return 'Enter valid mobile number';
                        return null;
                      },
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Continue',
                      isLoading: authState.isLoading,
                      onPressed: _sendOtp,
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.divider)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: AppColors.divider)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Google button
                    GestureDetector(
                      onTap: () async {
                        final success = await ref.read(authProvider.notifier).loginWithGoogle();
                        if (success && mounted) {
                          context.go(RouteNames.locationPermission);
                        }
                      },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Continue with Google', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 32),
                    Center(
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
