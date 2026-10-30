import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import 'job_status_buttons.dart';

class JobActionsScreen extends ConsumerStatefulWidget {
  const JobActionsScreen({
    super.key,
    required this.bookingId,
    required this.initialStatus,
    this.hasPartLines = false,
    this.hasPendingExtra = false,
  });

  final String bookingId;
  final String initialStatus;
  final bool hasPartLines;
  final bool hasPendingExtra;

  @override
  ConsumerState<JobActionsScreen> createState() => _JobActionsScreenState();
}

class _JobActionsScreenState extends ConsumerState<JobActionsScreen> {
  late String _status = widget.initialStatus;
  bool _busy = false;
  String? _error;

  Future<void> _advance() async {
    final buttons = JobStatusButtons(
      status: _status,
      hasPartLines: widget.hasPartLines,
      hasPendingExtra: widget.hasPendingExtra,
      onAction: () {},
    );
    setState(() => _busy = true);
    final result = await ref
        .read(jobTransitionApiProvider)
        .transition(widget.bookingId, buttons.nextStatus);
    if (!mounted) return;
    result.when(
      onOk: (next) => setState(() {
        _status = next;
        _busy = false;
        _error = null;
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
      appBar: AppBar(title: const Text('Job')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status, style: const TextStyle(color: Colors.white)),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            const Spacer(),
            JobStatusButtons(
              status: _status,
              hasPartLines: widget.hasPartLines,
              hasPendingExtra: widget.hasPendingExtra,
              busy: _busy,
              onAction: _advance,
            ),
          ],
        ),
      ),
    );
  }
}
