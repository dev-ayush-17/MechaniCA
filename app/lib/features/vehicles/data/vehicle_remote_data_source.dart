import '../../../core/api/generated/vehicles/vehicles_client.dart';
import '../../../core/error/result.dart';
import '../domain/vehicle.dart';
import 'vehicle_api_mapper.dart';

typedef BearerTokenProvider = Future<String?> Function();

abstract class VehicleRemotePort {
  Future<Result<List<Vehicle>>> list();

  Future<Result<Vehicle>> create(Vehicle draft, {required String idempotencyKey});

  Future<Result<Vehicle>> patch(Vehicle vehicle);

  Future<Result<void>> delete(String vehicleId);
}

class VehicleRemoteDataSource implements VehicleRemotePort {
  VehicleRemoteDataSource({
    required VehiclesClient client,
    required BearerTokenProvider token,
  })  : _client = client,
        _token = token;

  final VehiclesClient _client;
  final BearerTokenProvider _token;

  @override
  Future<Result<List<Vehicle>>> list() async {
    try {
      final auth = await _bearer();
      if (auth == null) return const Err(Unauthenticated());
      final response = await _client.listVehiclesV1VehiclesGet(authorization: auth);
      return Ok(response.items.map(vehicleFromDto).toList());
    } catch (_) {
      return const Err(Unavailable());
    }
  }

  @override
  Future<Result<Vehicle>> create(Vehicle draft, {required String idempotencyKey}) async {
    try {
      final auth = await _bearer();
      if (auth == null) return const Err(Unauthenticated());
      final saved = await _client.createVehicleV1VehiclesPost(
        body: createRequestFrom(draft),
        idempotencyKey: idempotencyKey,
        authorization: auth,
      );
      return Ok(vehicleFromDto(saved));
    } catch (_) {
      return const Err(Unavailable());
    }
  }

  @override
  Future<Result<Vehicle>> patch(Vehicle vehicle) async {
    try {
      final auth = await _bearer();
      if (auth == null) return const Err(Unauthenticated());
      final saved = await _client.patchVehicleV1VehiclesVehicleIdPatch(
        vehicleId: vehicle.id,
        body: patchRequestFrom(vehicle),
        authorization: auth,
      );
      return Ok(vehicleFromDto(saved));
    } catch (_) {
      return const Err(Unavailable());
    }
  }

  @override
  Future<Result<void>> delete(String vehicleId) async {
    try {
      final auth = await _bearer();
      if (auth == null) return const Err(Unauthenticated());
      await _client.deleteVehicleV1VehiclesVehicleIdDelete(
        vehicleId: vehicleId,
        authorization: auth,
      );
      return const Ok(null);
    } catch (_) {
      return const Err(Unavailable());
    }
  }

  Future<String?> _bearer() async {
    final token = await _token();
    if (token == null || token.isEmpty) return null;
    return 'Bearer $token';
  }
}
