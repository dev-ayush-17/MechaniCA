import '../models/service_model.dart';
import '../mock/mock_data.dart';
import '../mock/mock_delay.dart';

abstract class ServiceRepository {
  Future<List<ServiceModel>> getServices();
  Future<ServiceModel> getServiceById(String id);
}

class MockServiceRepository implements ServiceRepository {
  @override
  Future<List<ServiceModel>> getServices() async {
    await MockDelay.wait();
    return mockServices;
  }

  @override
  Future<ServiceModel> getServiceById(String id) async {
    await MockDelay.short();
    return mockServices.firstWhere((s) => s.id == id);
  }
}
