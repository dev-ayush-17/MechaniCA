import '../../../core/error/result.dart';
import 'saved_address.dart';

abstract class AddressApi {
  Future<Result<List<SavedAddress>>> list();

  Future<Result<SavedAddress>> create({
    required String label,
    required String line1,
    required String city,
    required String pincode,
    required double lat,
    required double lng,
    String? landmark,
    bool isDefault = false,
  });

  Future<Result<void>> delete(String addressId);
}
