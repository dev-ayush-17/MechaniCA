import '../../../core/error/result.dart';
import '../domain/vehicle.dart';
import '../domain/vehicle_repository.dart';

/// Offline demo vehicles with valid plates (no mock BR80Y 024).
class FakeVehicleRepository implements VehicleRepository {
  FakeVehicleRepository() {
    final now = DateTime.utc(2024, 1, 15);
    _vehicles.addAll([
      Vehicle(
        id: 'veh_seed_1',
        ownerId: 'demo',
        vehicleType: VehicleType.twoWheeler,
        brand: 'TVS',
        model: 'Apache RTR 160 4V',
        year: 2022,
        registrationNumber: 'BR01AB1234',
        fuelType: 'petrol',
        color: 'Matte Black',
        odometerKm: 12400,
        isPrimary: true,
        insuranceExpiry: '15 Jun 2025',
        pucExpiry: '18 Jan 2025',
        createdAt: now,
        updatedAt: now,
      ),
      Vehicle(
        id: 'veh_seed_2',
        ownerId: 'demo',
        vehicleType: VehicleType.twoWheeler,
        brand: 'Yamaha',
        model: 'MT-15',
        year: 2021,
        registrationNumber: 'BR02CD5678',
        fuelType: 'petrol',
        color: 'Cyan Storm',
        odometerKm: 8200,
        isPrimary: false,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }

  final List<Vehicle> _vehicles = [];

  @override
  Future<Result<List<Vehicle>>> listByOwner(String ownerId) async {
    return Ok(_vehicles.where((v) => v.ownerId == ownerId).toList());
  }

  @override
  Future<Result<Vehicle>> save(Vehicle vehicle) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (vehicle.isPrimary) {
      for (var i = 0; i < _vehicles.length; i++) {
        if (_vehicles[i].ownerId == vehicle.ownerId && _vehicles[i].id != vehicle.id) {
          _vehicles[i] = _vehicles[i].copyWith(isPrimary: false);
        }
      }
    }
    if (index >= 0) {
      _vehicles[index] = vehicle;
    } else {
      _vehicles.add(vehicle);
    }
    return Ok(vehicle);
  }

  @override
  Future<Result<void>> delete(String vehicleId, String ownerId) async {
    _vehicles.removeWhere((v) => v.id == vehicleId && v.ownerId == ownerId);
    return const Ok(null);
  }

  @override
  Future<Result<void>> syncFromServer(String ownerId) async => const Ok(null);
}
