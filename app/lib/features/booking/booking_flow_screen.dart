import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../composition/providers.dart';
import '../../core/error/result.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../models/booking_model.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';
import '../profile/domain/saved_address.dart';
import '../vehicles/domain/bike_mapper.dart';
import '../vehicles/domain/vehicle.dart';
import 'domain/booking.dart';
import 'domain/payment_method.dart';
import 'domain/repeat_prefill.dart';
import 'presentation/coupon_apply_field.dart';
import 'presentation/price_step.dart';
import 'presentation/service_step.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({super.key, this.repeat});

  final RepeatPrefill? repeat;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _step = 0;
  final _totalSteps = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    ref.read(bookingFlowProvider.notifier).reset();
    final userId = ref.read(authProvider).session?.userId;
    if (userId != null) {
      await ref.read(vehiclesControllerProvider.notifier).load(userId);
    }
    await ref.read(addressesControllerProvider.notifier).load();
    try {
      await ref.read(catalogServicesProvider.future);
    } catch (_) {}
    if (!mounted) return;
    _applyRepeat();
  }

  void _applyRepeat() {
    final repeat = widget.repeat;
    if (repeat == null) return;
    final vehicles = ref.read(vehiclesControllerProvider).vehicles;
    Vehicle? vehicle;
    for (final item in vehicles) {
      if (item.id == repeat.vehicleId) {
        vehicle = item;
        break;
      }
    }
    if (vehicle != null) {
      ref.read(bookingFlowProvider.notifier).selectBike(vehicle.toBikeModel());
    }
    final catalog = ref.read(catalogServicesProvider).valueOrNull;
    if (catalog != null) {
      for (final svc in catalog.services) {
        if (svc.code == repeat.serviceCode) {
          ref.read(bookingFlowProvider.notifier).selectService(serviceModelFromDefinition(svc));
          break;
        }
      }
    }
    final addresses = ref.read(addressesControllerProvider).items;
    SavedAddress? address;
    for (final item in addresses) {
      if (item.id == repeat.addressId) {
        address = item;
        break;
      }
    }
    ref.read(bookingFlowProvider.notifier).setAddressId(repeat.addressId);
    if (address != null) {
      ref.read(bookingFlowProvider.notifier).setPickupAddress(address.fullAddress);
    }
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
  }

  void _prev() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  Future<String?> _confirmBooking() async {
    if (!ref.read(networkOnlineProvider)) {
      return 'Connect to book.';
    }
    final flow = ref.read(bookingFlowProvider);
    if (flow.selectedBike == null || flow.selectedService == null) {
      return 'Pick a bike and a service first.';
    }

    final result = await ref.read(bookingApiProvider).create(
          vehicleId: flow.selectedBike!.id,
          serviceCode: flow.selectedService!.id,
          addressId: flow.addressId.isEmpty ? 'addr_home' : flow.addressId,
          paymentMethod: paymentMethodCode(flow.paymentMethod),
          mode: 'instant',
          urgency: 'normal',
          idempotencyKey: const Uuid().v4(),
          couponCode: flow.couponCode ?? '',
        );
    switch (result) {
      case Ok(:final value):
        await _persistCreated(flow, value);
        return null;
      case Err(:final failure):
        return failure.message;
    }
  }

  Future<void> _persistCreated(BookingFlowState flow, Booking created) async {
    final booking = BookingModel(
      id: created.id,
      userId: ref.read(authProvider).session?.userId ?? '',
      bikeId: flow.selectedBike!.id,
      bikeName: flow.selectedBike!.name,
      bikeNumber: flow.selectedBike!.registrationNumber,
      serviceId: flow.selectedService!.id,
      serviceName: flow.selectedService!.name,
      servicePrice: flow.selectedService!.price,
      status: created.status,
      serviceType: flow.isPickupDrop ? ServiceType.pickupDrop : ServiceType.visitWorkshop,
      scheduledDate: flow.selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      scheduledTime: flow.selectedTime ?? '10:00 AM',
      pickupAddress: flow.pickupAddress,
      couponCode: flow.couponCode,
      discount: flow.discount,
      pickupCharges: flow.pickupCharges,
      gst: flow.gst,
      totalAmount: created.totalPaise / 100,
      paymentMethod: flow.paymentMethod,
      createdAt: DateTime.now(),
      statusTimeline: [created.status.label],
    );
    await ref.read(bookingProvider.notifier).createBooking(booking);
    if (mounted) {
      ref.read(bookingFlowProvider.notifier).reset();
      context.pushReplacement(RouteNames.bookingSuccess, extra: created.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Bike', 'Service', 'Date & Time', 'Pickup', 'Address', 'Payment'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _prev,
        ),
        title: const Text('Book Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Column(
            children: [
              // Step indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: List.generate(_totalSteps, (i) {
                    final isDone = i < _step;
                    final isCurrent = i == _step;
                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDone || isCurrent ? AppColors.primaryRed : AppColors.divider,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          if (i < _totalSteps - 1) const SizedBox(width: 4),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Step ${_step + 1}: ${steps[_step]}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _Step1Bike(onNext: _next);
      case 1: return ServiceStep(onNext: _next);
      case 2: return _Step3DateTime(onNext: _next, leaveDateEmpty: widget.repeat != null);
      case 3: return _Step4Pickup(onNext: _next);
      case 4: return _Step5Address(onNext: _next);
      case 5: return PriceStep(onConfirm: _confirmBooking);
      default: return const SizedBox.shrink();
    }
  }
}

// ─── STEP 1: SELECT BIKE ──────────────────────────────────────────────────────

class _Step1Bike extends ConsumerWidget {
  final VoidCallback onNext;
  const _Step1Bike({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesState = ref.watch(vehiclesControllerProvider);
    final flow = ref.watch(bookingFlowProvider);
    final bikes = vehiclesState.asBikeModels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: vehiclesState.isLoading
              ? const ShimmerList(count: 2)
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bikes.length,
              itemBuilder: (_, i) {
                final bike = bikes[i];
                final selected = flow.selectedBike?.id == bike.id;
                return GestureDetector(
                  onTap: () => ref.read(bookingFlowProvider.notifier).selectBike(bike),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? AppColors.primaryRed : AppColors.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.motorcycle, size: 26, color: AppColors.primaryRed),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bike.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                              Text(bike.registrationNumber, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (selected) const Icon(Icons.check_circle, color: AppColors.primaryRed, size: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(label: 'Next', onPressed: flow.selectedBike != null ? onNext : null),
        ),
      ],
    );
  }
}

// ─── STEP 3: DATE & TIME ──────────────────────────────────────────────────────

class _Step3DateTime extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final bool leaveDateEmpty;
  const _Step3DateTime({required this.onNext, this.leaveDateEmpty = false});
  @override
  ConsumerState<_Step3DateTime> createState() => _Step3DateTimeState();
}

class _Step3DateTimeState extends ConsumerState<_Step3DateTime> {
  DateTime? _selectedDate;
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    if (!widget.leaveDateEmpty) {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
    }
  }

  final _times = ['9:00 AM', '10:00 AM', '11:00 AM', '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM'];

  List<DateTime> get _dates {
    return List.generate(14, (i) => DateTime.now().add(Duration(days: i + 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Date', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 82,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dates.length,
                    itemBuilder: (_, i) {
                      final d = _dates[i];
                      final selected = _selectedDate != null &&
                          d.day == _selectedDate!.day &&
                          d.month == _selectedDate!.month;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 54,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primaryRed : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: selected ? AppColors.primaryRed : AppColors.divider),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(DateFormat('EEE').format(d), style: TextStyle(color: selected ? Colors.white70 : AppColors.textTertiary, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text('${d.day}', style: TextStyle(color: selected ? Colors.white : Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              Text(DateFormat('MMM').format(d), style: TextStyle(color: selected ? Colors.white70 : AppColors.textTertiary, fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Select Time Slot', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _times.map((t) {
                    final selected = _selectedTime == t;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTime = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primaryRed : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AppColors.primaryRed : AppColors.divider),
                        ),
                        child: Text(t, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: 'Next',
            onPressed: _selectedDate != null && _selectedTime != null
                ? () {
                    ref.read(bookingFlowProvider.notifier)
                      ..selectDate(_selectedDate!)
                      ..selectTime(_selectedTime!);
                    widget.onNext();
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

// ─── STEP 4: PICKUP OR WORKSHOP ───────────────────────────────────────────────

class _Step4Pickup extends ConsumerWidget {
  final VoidCallback onNext;
  const _Step4Pickup({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(bookingFlowProvider);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _PickupOption(
                  icon: Icons.local_shipping_outlined,
                  title: 'Pickup & Drop',
                  subtitle: 'We will pick your bike from your location & drop it back.',
                  fee: '₹100 extra',
                  selected: flow.isPickupDrop,
                  onTap: () => ref.read(bookingFlowProvider.notifier).setPickupDrop(true),
                ),
                const SizedBox(height: 16),
                _PickupOption(
                  icon: Icons.store_outlined,
                  title: 'Visit Workshop',
                  subtitle: 'You can visit our workshop directly.',
                  fee: 'Free',
                  selected: !flow.isPickupDrop,
                  onTap: () => ref.read(bookingFlowProvider.notifier).setPickupDrop(false),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(label: 'Next', onPressed: onNext),
        ),
      ],
    );
  }
}

class _PickupOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String fee;
  final bool selected;
  final VoidCallback onTap;

  const _PickupOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fee,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.primaryRed : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (selected ? AppColors.primaryRed : AppColors.textTertiary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: selected ? AppColors.primaryRed : AppColors.textTertiary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 8),
                  Text(fee, style: TextStyle(color: selected ? AppColors.primaryRed : AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.primaryRed, size: 24),
          ],
        ),
      ),
    );
  }
}

// ─── STEP 5: ADDRESS & COUPON ─────────────────────────────────────────────────

class _Step5Address extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _Step5Address({required this.onNext});
  @override
  ConsumerState<_Step5Address> createState() => _Step5AddressState();
}

class _Step5AddressState extends ConsumerState<_Step5Address> {
  late final TextEditingController _addrCtrl;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(bookingFlowProvider).pickupAddress;
    _addrCtrl = TextEditingController(
      text: existing ?? 'Rajendra Nagar, Patna, Bihar',
    );
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(bookingFlowProvider);
    final saved = ref.watch(addressesControllerProvider).items;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (flow.isPickupDrop) ...[
                  const Text('Pickup Address', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  AppTextField(
                    hint: 'Enter your address',
                    controller: _addrCtrl,
                    maxLines: 2,
                    onChanged: (v) => ref.read(bookingFlowProvider.notifier).setPickupAddress(v),
                    suffix: const Padding(padding: EdgeInsets.all(14), child: Icon(Icons.my_location, color: AppColors.primaryRed, size: 18)),
                  ),
                  const SizedBox(height: 8),
                  ...saved.map((a) => GestureDetector(
                    onTap: () {
                      _addrCtrl.text = a.fullAddress;
                      ref.read(bookingFlowProvider.notifier)
                        ..setPickupAddress(a.fullAddress)
                        ..setAddressId(a.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: flow.addressId == a.id
                              ? AppColors.primaryRed
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(a.label == 'Home' ? Icons.home_outlined : Icons.work_outline, size: 16, color: AppColors.primaryRed),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(a.fullAddress, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          )),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),
                ],
                const CouponApplyField(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(label: 'Next', onPressed: widget.onNext),
        ),
      ],
    );
  }
}

