import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared/app_widgets.dart';

class RescheduleScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const RescheduleScreen({super.key, required this.bookingId});
  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 2));
  String? _time;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reschedule Booking')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Date', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (_, child) => Theme(data: ThemeData.dark(), child: child!),
                );
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppColors.primaryRed, size: 20),
                    const SizedBox(width: 12),
                    Text('${_date.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][_date.month-1]} ${_date.year}',
                        style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('New Time', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: ['9:00 AM', '10:00 AM', '11:00 AM', '2:00 PM', '4:00 PM'].map((t) {
              final sel = _time == t;
              return GestureDetector(
                onTap: () => setState(() => _time = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primaryRed : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.primaryRed : AppColors.divider),
                  ),
                  child: Text(t, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 13)),
                ),
              );
            }).toList()),
            const Spacer(),
            AppButton(
              label: 'Confirm Reschedule',
              isLoading: _isLoading,
              onPressed: _time == null ? null : () async {
                setState(() => _isLoading = true);
                await ref.read(bookingRepositoryProvider).rescheduleBooking(widget.bookingId, _date, _time!);
                if (context.mounted) {
                  setState(() => _isLoading = false);
                  showAppSnackbar(context, 'Booking rescheduled successfully!');
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
