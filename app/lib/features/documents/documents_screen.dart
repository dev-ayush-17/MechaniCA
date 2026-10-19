import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../mock/mock_data.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';

// ─── DOCUMENTS SCREEN ─────────────────────────────────────────────────────────

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});
  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentProvider.notifier).load('bike_001');
    });
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'insurance': return Icons.shield_outlined;
      case 'puc': return Icons.verified_outlined;
      case 'license': return Icons.badge_outlined;
      default: return Icons.description_outlined;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'valid': return AppColors.success;
      case 'expiring': return AppColors.warning;
      case 'expired': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Documents'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showUploadSheet(context),
          ),
        ],
      ),
      body: docsAsync.when(
        loading: () => const ShimmerList(),
        error: (_, __) => const ErrorState(message: 'Failed to load documents'),
        data: (docs) => docs.isEmpty
            ? EmptyState(
                icon: Icons.description_outlined,
                title: 'No Documents',
                subtitle: 'Upload your bike documents to keep them safe',
                actionLabel: 'Upload Document',
                onAction: () => _showUploadSheet(context),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  final color = _statusColor(doc.status);
                  return GestureDetector(
                    onTap: () => context.push(RouteNames.documentViewer, extra: {'title': doc.title, 'docType': doc.type}),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(_docIcon(doc.type), color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                if (doc.documentNumber != null)
                                  Text(doc.documentNumber!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                if (doc.expiryDate != null)
                                  Text(
                                    'Expires: ${doc.expiryDate!.day}/${doc.expiryDate!.month}/${doc.expiryDate!.year}',
                                    style: TextStyle(color: color, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              StatusBadge(label: doc.status.toUpperCase(), color: color),
                              const SizedBox(height: 8),
                              const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 80));
                },
              ),
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Document', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            ...[('Insurance Policy', 'insurance'), ('RC Book', 'rc'), ('PUC Certificate', 'puc'), ('Driving License', 'license')].map((d) =>
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  showAppSnackbar(context, '${d.$1} uploaded successfully!');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.upload_file_rounded, color: AppColors.primaryRed, size: 20),
                    const SizedBox(width: 12),
                    Text(d.$1, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 16),
                  ]),
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }
}

// ─── DOCUMENT VIEWER SCREEN ───────────────────────────────────────────────────

class DocumentViewerScreen extends StatelessWidget {
  final String title;
  final String docType;
  const DocumentViewerScreen({super.key, required this.title, required this.docType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: () => showAppSnackbar(context, 'Document downloaded!')),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () => showAppSnackbar(context, 'Sharing document...')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Dummy document preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.elevated,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_rounded, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(title, style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Document Preview', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: const Text('Valid Document', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Download PDF',
              icon: Icons.download_rounded,
              onPressed: () => showAppSnackbar(context, 'PDF downloaded!'),
            ),
          ],
        ),
      ),
    );
  }
}
