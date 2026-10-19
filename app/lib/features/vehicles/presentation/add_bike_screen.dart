import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../domain/indian_plate.dart';
import '../domain/vehicle.dart';

class AddBikeScreen extends ConsumerStatefulWidget {
  const AddBikeScreen({super.key});
  @override
  ConsumerState<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends ConsumerState<AddBikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  String _fuelType = 'petrol';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _regCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(authProvider).session?.userId;
    if (userId == null) return;
    setState(() => _isLoading = true);
    final now = DateTime.now().toUtc();
    final vehicle = Vehicle(
      id: '',
      ownerId: userId,
      vehicleType: VehicleType.twoWheeler,
      brand: _brandCtrl.text.trim(),
      model: _nameCtrl.text.trim(),
      year: 2023,
      registrationNumber: _regCtrl.text.trim(),
      fuelType: _fuelType,
      odometerKm: 0,
      color: 'Black',
      createdAt: now,
      updatedAt: now,
    );
    final ok = await ref.read(vehiclesControllerProvider.notifier).save(vehicle);
    if (mounted) {
      setState(() => _isLoading = false);
      if (!ok) {
        final message = ref.read(vehiclesControllerProvider).errorMessage ??
            invalidPlateMessage;
        showAppSnackbar(context, message);
        return;
      }
      if (!ref.read(networkOnlineProvider)) {
        showAppSnackbar(context, 'Saved on this phone');
      } else {
        showAppSnackbar(context, 'Bike added successfully!');
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add New Bike')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Bike Name'),
              AppTextField(
                hint: 'e.g. Apache RTR 160 4V',
                controller: _nameCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _label('Brand'),
              AppTextField(
                hint: 'e.g. TVS, Bajaj, Hero',
                controller: _brandCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _label('Registration Number'),
              AppTextField(
                hint: 'e.g. BR01AB1234',
                controller: _regCtrl,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!isValidIndianPlate(v)) return invalidPlateMessage;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _label('Fuel Type'),
              Row(
                children: ['petrol', 'electric', 'cng'].map((f) {
                  final selected = _fuelType == f;
                  return GestureDetector(
                    onTap: () => setState(() => _fuelType = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryRed : AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.primaryRed : AppColors.inputBorder,
                        ),
                      ),
                      child: Text(
                        f.toUpperCase(),
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              AppButton(label: 'Add Bike', isLoading: _isLoading, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
