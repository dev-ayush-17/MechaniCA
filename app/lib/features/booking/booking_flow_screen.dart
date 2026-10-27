import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../composition/providers.dart';
import '../../core/error/result.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../navigation/route_names.dart';
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

  DateTime? _scheduledStart(DateTime? date, String? time) {
    if (date == null || time == null) return null;
    final match = RegExp(r'(\d+):(\d+)\s*(AM|PM)').firstMatch(time);
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (minute != 0) return null;
    final pm = match.group(3) == 'PM';
    if (pm && hour != 12) hour += 12;
    if (!pm && hour == 12) hour = 0;
    final local = DateTime(date.year, date.month, date.day, hour);
    return local.toUtc();
  }

  Future<String?> _confirmBooking() async {
    if (!ref.read(networkOnlineProvider)) {
      return 'Connect to book.';
    }
    final flow = ref.read(bookingFlowProvider);
    if (flow.selectedBike == null || flow.selectedService == null) {
      return 'Pick a bike and a service first.';
    }
    if (flow.addressId.isEmpty) {
      return 'Save a service address first.';
    }
    final scheduled = flow.bookAsap
        ? null
        : _scheduledStart(flow.selectedDate, flow.selectedTime);
    if (!flow.bookAsap && scheduled == null) {
      return 'Pick an on-the-hour slot, or choose as soon as possible.';
    }

    final result = await ref.read(bookingApiProvider).create(
          vehicleId: flow.selectedBike!.id,
          serviceCode: flow.selectedService!.id,
          addressId: flow.addressId,
          paymentMethod: paymentMethodCode(flow.paymentMethod),
          mode: flow.bookAsap ? 'instant' : 'scheduled',
          urgency: 'normal',
          idempotencyKey: const Uuid().v4(),
          scheduledStart: scheduled,
          couponCode: flow.couponCode ?? '',
        );
    switch (result) {
      case Ok(:final value):
        _openCreated(flow, value);
        return null;
      case Err(:final failure):
        return failure.message;
    }
  }

  void _openCreated(BookingFlowState flow, Booking created) {
    final named = created.serviceName.isEmpty
        ? (flow.selectedService?.name ?? created.serviceCode)
        : created.serviceName;
    final booking = Booking(
      id: created.id,
      displayNumber: created.displayNumber,
      status: created.status,
      serviceCode: created.serviceCode,
      mode: created.mode,
      urgency: created.urgency,
      totalPaise: created.totalPaise,
      cancelFeePaise: created.cancelFeePaise,
      version: created.version,
      vehicleId: created.vehicleId.isEmpty ? flow.selectedBike!.id : created.vehicleId,
      serviceName: named,
      addressId: created.addressId.isEmpty ? flow.addressId : created.addressId,
      scheduledStart: created.scheduledStart,
      paymentMethod: created.paymentMethod.isEmpty
          ? paymentMethodCode(flow.paymentMethod)
          : created.paymentMethod,
    );
    ref.invalidate(homeBookingsProvider);
    ref.read(bookingFlowProvider.notifier).reset();
    if (mounted) {
      context.pushReplacement(RouteNames.bookingSuccess, extra: booking);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Bike',
      'Service',
      'Date & Time',
      'Pickup',
      'Address',
      l10nOf(context).bookingReviewStep,
    ];

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
  bool _asap = true;

  @override
  void initState() {
    super.initState();
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('As soon as possible', style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                    'A mechanic is offered as soon as you submit.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(
                    _asap ? Icons.check_circle : Icons.circle_outlined,
                    color: AppColors.primaryRed,
                  ),
                  onTap: () => setState(() => _asap = true),
                ),
                const Text('Select Date', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 82,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dates.length,
                    itemBuilder: (_, i) {
                      final d = _dates[i];
                      final selected = !_asap &&
                          _selectedDate != null &&
                          d.day == _selectedDate!.day &&
                          d.month == _selectedDate!.month;
                      return GestureDetector(
                        onTap: () => setState(() {
                        _asap = false;
                        _selectedDate = d;
                      }),
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
                    final selected = !_asap && _selectedTime == t;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _asap = false;
                        _selectedTime = t;
                      }),
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
            onPressed: _asap || (_selectedDate != null && _selectedTime != null)
                ? () {
                    final notifier = ref.read(bookingFlowProvider.notifier);
                    notifier.setBookAsap(_asap);
                    if (!_asap && _selectedDate != null && _selectedTime != null) {
                      notifier
                        ..selectDate(_selectedDate!)
                        ..selectTime(_selectedTime!);
                    }
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
  final _pinCtrl = TextEditingController(text: '800001');
  double? _lat;
  double? _lng;
  String? _locationNote;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(bookingFlowProvider).pickupAddress;
    _addrCtrl = TextEditingController(text: existing ?? '');
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _useDeviceLocation() async {
    final fix = await ref.read(deviceLocationProvider).current();
    if (!mounted) return;
    setState(() {
      if (!fix.hasPoint) {
        _locationNote = fix.message ?? 'Location permission was denied.';
        return;
      }
      _lat = fix.lat;
      _lng = fix.lng;
      _locationNote =
          '${fix.lat!.toStringAsFixed(5)}, ${fix.lng!.toStringAsFixed(5)}';
      if (_addrCtrl.text.trim().isEmpty) {
        _addrCtrl.text = 'Current location';
      }
    });
  }

  void _usePatna() {
    setState(() {
      _lat = 25.5941;
      _lng = 85.1376;
      _locationNote = '25.59410, 85.13760';
      _addrCtrl.text = 'Rajendra Nagar, Patna';
      _pinCtrl.text = '800001';
    });
  }

  Future<void> _saveAddress() async {
    final lat = _lat;
    final lng = _lng;
    final line = _addrCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (lat == null || lng == null) {
      setState(() => _locationNote = 'Use current location or the Patna address first.');
      return;
    }
    if (line.length < 3) {
      setState(() => _locationNote = 'Enter a street address.');
      return;
    }
    setState(() => _saving = true);
    final error = await ref.read(addressesControllerProvider.notifier).add(
          label: 'Service',
          line1: line,
          city: 'Patna',
          pincode: pin,
          lat: lat,
          lng: lng,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _locationNote = error;
      });
      return;
    }
    final items = ref.read(addressesControllerProvider).items;
    final saved = items.cast<SavedAddress?>().lastWhere(
          (item) => item != null && item.line1 == line,
          orElse: () => items.isEmpty ? null : items.last,
        );
    if (saved != null) {
      ref.read(bookingFlowProvider.notifier)
        ..setAddressId(saved.id)
        ..setPickupAddress(saved.fullAddress);
    }
    setState(() {
      _saving = false;
      _locationNote = saved == null ? 'Address saved.' : 'Saved ${saved.fullAddress}';
    });
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
                const Text('Service address', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  AppTextField(
                    hint: 'Enter your address',
                    controller: _addrCtrl,
                    maxLines: 2,
                    onChanged: (v) => ref.read(bookingFlowProvider.notifier).setPickupAddress(v),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'PIN code',
                    controller: _pinCtrl,
                    label: 'PIN',
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Use current location',
                    icon: Icons.my_location,
                    isOutlined: true,
                    onPressed: _useDeviceLocation,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Use Patna service area',
                    isOutlined: true,
                    onPressed: _usePatna,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: _saving ? 'Saving…' : 'Save this address',
                    onPressed: _saving ? null : _saveAddress,
                  ),
                  if (_locationNote != null) ...[
                    const SizedBox(height: 8),
                    Text(_locationNote!, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
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
                const CouponApplyField(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: 'Next',
            onPressed: flow.addressId.isEmpty ? null : widget.onNext,
          ),
        ),
      ],
    );
  }
}

