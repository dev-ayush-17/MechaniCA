import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../mock/mock_data.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';


class DigitalInspectionScreen extends ConsumerWidget {
  final String bookingId;
  const DigitalInspectionScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspAsync = ref.watch(inspectionProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Digital Inspection'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: inspAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
        error: (_, __) => ErrorState(message: 'Failed to load inspection'),
        data: (insp) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Before photos
              const Text('Before Service', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _PhotoGrid(photos: insp.beforePhotos, onTap: (i) => context.push(RouteNames.photoGallery, extra: {'photos': insp.beforePhotos, 'index': i})),
              const SizedBox(height: 20),

              // After photos
              const Text('After Service', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _PhotoGrid(photos: insp.afterPhotos, onTap: (i) => context.push(RouteNames.photoGallery, extra: {'photos': insp.afterPhotos, 'index': i})),
              const SizedBox(height: 20),

              // Observations
              const Text('Observations', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...insp.observations.map((o) => _BulletPoint(o, AppColors.info)),
              const SizedBox(height: 20),

              // Recommendations
              const Text('Recommendations', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...insp.recommendations.map((r) => _BulletPoint(r, AppColors.warning)),
              const SizedBox(height: 20),

              // Parts Changed
              const Text('Parts Changed', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...insp.partsChanged.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.settings_rounded, size: 16, color: AppColors.primaryRed),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text('x${p.quantity}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text('₹${p.price.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 20),

              // Mechanic notes
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mechanic Notes', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(insp.mechanicNotes, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'View Full Screen',
                isOutlined: true,
                onPressed: () => context.push(RouteNames.photoGallery, extra: {'photos': insp.afterPhotos, 'index': 0}),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<String> photos;
  final void Function(int) onTap;
  const _PhotoGrid({required this.photos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: photos.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => onTap(i),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            photos[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surfaceElevated,
              child: const Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 36),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _BulletPoint(String text, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4))),
      ],
    ),
  );
}

// ─── PHOTO GALLERY ────────────────────────────────────────────────────────────

class PhotoGalleryScreen extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  const PhotoGalleryScreen({super.key, required this.photos, required this.initialIndex});
  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late PageController _ctrl;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text('${_current + 1} / ${widget.photos.length}', style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.photos[i],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 80),
            ),
          ),
        ),
      ),
    );
  }
}
