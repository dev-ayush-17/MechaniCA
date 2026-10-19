import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/auth/domain/auth_service.dart';
import 'package:mechupp_app/features/bikes/my_bikes_screen.dart';
import 'package:mechupp_app/features/vehicles/domain/vehicle.dart';
import 'package:mechupp_app/features/vehicles/domain/vehicle_repository.dart';

class _EmptyVehicleRepo implements VehicleRepository {
  @override
  Future<Result<List<Vehicle>>> listByOwner(String ownerId) async => const Ok([]);

  @override
  Future<Result<Vehicle>> save(Vehicle vehicle) async => Ok(vehicle);

  @override
  Future<Result<void>> delete(String vehicleId, String ownerId) async => const Ok(null);

  @override
  Future<Result<void>> syncFromServer(String ownerId) async => const Ok(null);
}

class _OneVehicleRepo implements VehicleRepository {
  @override
  Future<Result<List<Vehicle>>> listByOwner(String ownerId) async {
    return Ok([
      Vehicle(
        id: 'bike_test',
        ownerId: ownerId,
        vehicleType: VehicleType.twoWheeler,
        brand: 'TVS',
        model: 'Apache RTR 160 4V',
        year: 2022,
        registrationNumber: 'BR01AB1234',
        fuelType: 'petrol',
        odometerKm: 12400,
        color: 'Matte Black',
        isPrimary: true,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
      ),
    ]);
  }

  @override
  Future<Result<Vehicle>> save(Vehicle vehicle) async => Ok(vehicle);

  @override
  Future<Result<void>> delete(String vehicleId, String ownerId) async => const Ok(null);

  @override
  Future<Result<void>> syncFromServer(String ownerId) async => const Ok(null);
}

Future<void> _pumpBikes(WidgetTester tester, VehicleRepository repo) async {
  final session = Session(
    userId: 'usr_001',
    idToken: 'tok',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    role: 'customer',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(repo),
        authProvider.overrideWith(
          (ref) => AuthNotifier(
            ref.watch(authServiceProvider),
            ref.watch(accountApiProvider),
          )..state = AuthState(session: session),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const MyBikesScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('empty_list_shows_no_bikes_copy', (tester) async {
    await _pumpBikes(tester, _EmptyVehicleRepo());
    await tester.pumpAndSettle();

    expect(find.text('No Bikes Added'), findsOneWidget);
    expect(find.text('Add your first bike to get started'), findsOneWidget);
  });

  testWidgets('list_with_one_vehicle_shows_registration', (tester) async {
    await _pumpBikes(tester, _OneVehicleRepo());
    await tester.pumpAndSettle();

    expect(find.text('BR01AB1234'), findsOneWidget);
  });
}
