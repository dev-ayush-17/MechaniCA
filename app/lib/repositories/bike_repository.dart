import '../models/bike_model.dart';
import '../mock/mock_data.dart';
import '../mock/mock_delay.dart';

abstract class BikeRepository {
  Future<List<BikeModel>> getBikes(String userId);
  Future<BikeModel> addBike(BikeModel bike);
  Future<BikeModel> updateBike(BikeModel bike);
  Future<void> deleteBike(String bikeId);
  Future<void> setPrimaryBike(String bikeId, String userId);
}

class MockBikeRepository implements BikeRepository {
  final List<BikeModel> _bikes = List.from(mockBikes);

  @override
  Future<List<BikeModel>> getBikes(String userId) async {
    await MockDelay.wait();
    return _bikes.where((b) => b.userId == userId).toList();
  }

  @override
  Future<BikeModel> addBike(BikeModel bike) async {
    await MockDelay.wait();
    _bikes.add(bike);
    return bike;
  }

  @override
  Future<BikeModel> updateBike(BikeModel bike) async {
    await MockDelay.wait();
    final index = _bikes.indexWhere((b) => b.id == bike.id);
    if (index != -1) _bikes[index] = bike;
    return bike;
  }

  @override
  Future<void> deleteBike(String bikeId) async {
    await MockDelay.wait();
    _bikes.removeWhere((b) => b.id == bikeId);
  }

  @override
  Future<void> setPrimaryBike(String bikeId, String userId) async {
    await MockDelay.short();
    for (var i = 0; i < _bikes.length; i++) {
      if (_bikes[i].userId == userId) {
        _bikes[i] = _bikes[i].copyWith(isPrimary: _bikes[i].id == bikeId);
      }
    }
  }
}
