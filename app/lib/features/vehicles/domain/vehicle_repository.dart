import '../../../core/error/result.dart';
import 'vehicle.dart';

abstract class VehicleRepository {
  Future<Result<List<Vehicle>>> listByOwner(String ownerId);

  Future<Result<Vehicle>> save(Vehicle vehicle);

  Future<Result<void>> delete(String vehicleId, String ownerId);

  Future<Result<void>> syncFromServer(String ownerId);
}
