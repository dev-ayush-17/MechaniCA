import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/bikes/my_bikes_screen.dart';
import 'package:mechupp_app/models/bike_model.dart';
import 'package:mechupp_app/providers/app_providers.dart';
import 'package:mechupp_app/repositories/bike_repository.dart';

class _EmptyBikeRepo implements BikeRepository {
  @override
  Future<List<BikeModel>> getBikes(String userId) async => [];

  @override
  Future<BikeModel> addBike(BikeModel bike) async => bike;

  @override
  Future<BikeModel> updateBike(BikeModel bike) async => bike;

  @override
  Future<void> deleteBike(String bikeId) async {}

  @override
  Future<void> setPrimaryBike(String bikeId, String userId) async {}
}

class _OneBikeRepo implements BikeRepository {
  static final _bike = BikeModel(
    id: 'bike_test',
    userId: 'usr_001',
    name: 'Apache RTR 160 4V',
    brand: 'TVS',
    model: 'Apache RTR 160 4V',
    registrationNumber: 'BR01AB1234',
    year: 2022,
    fuelType: 'petrol',
    odometer: 12400,
    color: 'Matte Black',
    isPrimary: true,
    addedAt: DateTime(2024, 1, 15),
  );

  @override
  Future<List<BikeModel>> getBikes(String userId) async => [_bike];

  @override
  Future<BikeModel> addBike(BikeModel bike) async => bike;

  @override
  Future<BikeModel> updateBike(BikeModel bike) async => bike;

  @override
  Future<void> deleteBike(String bikeId) async {}

  @override
  Future<void> setPrimaryBike(String bikeId, String userId) async {}
}

Future<void> _pumpBikes(WidgetTester tester, BikeRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bikeRepositoryProvider.overrideWithValue(repo),
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
    await _pumpBikes(tester, _EmptyBikeRepo());
    await tester.pumpAndSettle();

    expect(find.text('No Bikes Added'), findsOneWidget);
    expect(find.text('Add your first bike to get started'), findsOneWidget);
  });

  testWidgets('list_with_one_vehicle_shows_registration', (tester) async {
    await _pumpBikes(tester, _OneBikeRepo());
    await tester.pumpAndSettle();

    expect(find.text('BR01AB1234'), findsOneWidget);
  });
}
