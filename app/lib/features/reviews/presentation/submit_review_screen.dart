import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/shared/app_widgets.dart';

class SubmitReviewScreen extends ConsumerStatefulWidget {
  const SubmitReviewScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends ConsumerState<SubmitReviewScreen> {
  int _stars = 5;
  final _text = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _done = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = ref.read(authProvider).session?.idToken ?? 'fake';
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(reviewRepositoryProvider).submit(
          token: token,
          bookingId: widget.bookingId,
          stars: _stars,
          text: _text.text,
        );
    if (!mounted) return;
    result.when(
      onOk: (_) => setState(() {
        _busy = false;
        _done = true;
      }),
      onErr: (failure) => setState(() {
        _busy = false;
        _error = failure.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rate your mechanic')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars ? Icons.star : Icons.star_border,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
            TextField(
              controller: _text,
              maxLength: 500,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Optional comments',
                hintStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            if (_done)
              const Text('Thanks for the review.', style: TextStyle(color: AppColors.success)),
            const Spacer(),
            AppButton(
              label: 'Submit review',
              isLoading: _busy,
              onPressed: _done ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
