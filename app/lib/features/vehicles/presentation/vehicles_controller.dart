import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/bike_model.dart';
import '../domain/bike_mapper.dart';
import '../domain/vehicle.dart';
import '../domain/vehicle_repository.dart';

class VehiclesState {
  const VehiclesState({
    this.vehicles = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Vehicle> vehicles;
  final bool isLoading;
  final String? errorMessage;

  List<BikeModel> get asBikeModels => vehicles.map((v) => v.toBikeModel()).toList();
}

class VehiclesController extends StateNotifier<VehiclesState> {
  VehiclesController(this._repo) : super(const VehiclesState());

  final VehicleRepository _repo;
  String? _ownerId;

  Future<void> load(String ownerId) async {
    _ownerId = ownerId;
    state = const VehiclesState(isLoading: true);
    final result = await _repo.listByOwner(ownerId);
    result.when(
      onOk: (list) => state = VehiclesState(vehicles: list),
      onErr: (failure) => state = VehiclesState(errorMessage: failure.message),
    );
  }

  Future<bool> save(Vehicle vehicle) async {
    final result = await _repo.save(vehicle);
    return result.when(
      onOk: (saved) {
        final list = [...state.vehicles];
        final index = list.indexWhere((v) => v.id == saved.id);
        if (index >= 0) {
          list[index] = saved;
        } else {
          list.add(saved);
        }
        if (saved.isPrimary) {
          for (var i = 0; i < list.length; i++) {
            if (list[i].ownerId == saved.ownerId && list[i].id != saved.id) {
              list[i] = list[i].copyWith(isPrimary: false);
            }
          }
        }
        state = VehiclesState(vehicles: list);
        return true;
      },
      onErr: (failure) {
        state = VehiclesState(vehicles: state.vehicles, errorMessage: failure.message);
        return false;
      },
    );
  }

  Future<void> delete(String vehicleId) async {
    final ownerId = _ownerId;
    if (ownerId == null) return;
    await _repo.delete(vehicleId, ownerId);
    state = VehiclesState(
      vehicles: state.vehicles.where((v) => v.id != vehicleId).toList(),
    );
  }

  Vehicle? byId(String id) {
    for (final v in state.vehicles) {
      if (v.id == id) return v;
    }
    return null;
  }
}
