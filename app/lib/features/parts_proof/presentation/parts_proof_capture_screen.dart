import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../../booking/domain/complete_gate.dart';
import '../domain/parts_proof.dart';
import '../../../composition/providers.dart';

/// Mechanic capture of the three required parts photos (FR-MEC-008).
class PartsProofCaptureScreen extends ConsumerStatefulWidget {
  const PartsProofCaptureScreen({
    super.key,
    required this.bookingId,
    required this.lineId,
    this.queue,
    this.pickImage,
    this.hasPartReplacementLine = true,
  });

  final String bookingId;
  final String lineId;
  final ProofUploadQueue? queue;
  final Future<String?> Function(ProofKind kind)? pickImage;
  final bool hasPartReplacementLine;

  @override
  ConsumerState<PartsProofCaptureScreen> createState() =>
      _PartsProofCaptureScreenState();
}

class _PartsProofCaptureScreenState extends ConsumerState<PartsProofCaptureScreen> {
  late final ProofUploadQueue _queue;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _queue = widget.queue ?? ProofUploadQueue();
  }

  Future<void> _capture(ProofKind kind) async {
    final picker = widget.pickImage ?? _defaultPick;
    final path = await picker(kind);
    if (path == null || !mounted) return;
    setState(() {
      _queue.enqueue(QueuedProof(kind: kind, localPath: path));
      _error = null;
    });
    final token = ref.read(authProvider).session?.idToken;
    if (token == null) return;
    setState(() => _busy = true);
    final result = await ref.read(partsProofRepositoryProvider).create(
          token: token,
          bookingId: widget.bookingId,
          lineId: widget.lineId,
          kind: kind,
        );
    if (!mounted) return;
    result.when(
      onOk: (proof) {
        _queue.enqueue(
          QueuedProof(kind: kind, localPath: path, storagePath: proof.path, uploaded: true),
        );
        setState(() => _busy = false);
      },
      onErr: (failure) => setState(() {
        _busy = false;
        _error = failure.message;
      }),
    );
  }

  Future<String?> _defaultPick(ProofKind kind) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    return file?.path;
  }

  bool get _blocked => completeBlockedWithoutPhotos(
        hasPartReplacementLine: widget.hasPartReplacementLine,
        queuedOrStoredCount: _queue.queuedCount,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Parts photos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload before, after, and old-part photos before completing.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            for (final kind in ProofKind.values) ...[
              _ProofSlot(
                kind: kind,
                queued: _queue[kind],
                onCapture: _busy ? null : () => _capture(kind),
              ),
              const SizedBox(height: 10),
            ],
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            const Spacer(),
            AppButton(
              label: _blocked ? 'Complete (photos required)' : 'Complete',
              onPressed: _blocked ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofSlot extends StatelessWidget {
  const _ProofSlot({required this.kind, required this.queued, required this.onCapture});

  final ProofKind kind;
  final QueuedProof? queued;
  final VoidCallback? onCapture;

  @override
  Widget build(BuildContext context) {
    final filled = queued != null;
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onCapture,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                filled ? Icons.check_circle : Icons.photo_camera_outlined,
                color: filled ? AppColors.success : AppColors.primaryRed,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  kind.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                filled ? 'Queued' : 'Capture',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
