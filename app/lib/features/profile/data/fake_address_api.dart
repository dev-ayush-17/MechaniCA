import '../../../core/error/result.dart';
import '../domain/address_api.dart';
import '../domain/saved_address.dart';

class FakeAddressApi implements AddressApi {
  FakeAddressApi([List<SavedAddress>? seed]) : items = [...?seed];

  final List<SavedAddress> items;

  @override
  Future<Result<List<SavedAddress>>> list() async => Ok(List.of(items));

  @override
  Future<Result<SavedAddress>> create({
    required String label,
    required String line1,
    required String city,
    required String pincode,
    required double lat,
    required double lng,
    String? landmark,
    bool isDefault = false,
  }) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pincode.trim())) {
      return const Err(InvalidInput('Enter a 6-digit PIN code.'));
    }
    if (items.length >= 10) {
      return const Err(InvalidInput('You can save up to 10 addresses.'));
    }
    final address = SavedAddress(
      id: 'addr_${items.length + 1}',
      label: label.trim(),
      line1: line1.trim(),
      city: city.trim(),
      pincode: pincode.trim(),
      lat: lat,
      lng: lng,
      isDefault: isDefault || items.isEmpty,
      landmark: landmark,
    );
    if (address.isDefault) {
      for (var i = 0; i < items.length; i++) {
        final current = items[i];
        items[i] = SavedAddress(
          id: current.id,
          label: current.label,
          line1: current.line1,
          city: current.city,
          pincode: current.pincode,
          lat: current.lat,
          lng: current.lng,
          isDefault: false,
          landmark: current.landmark,
        );
      }
    }
    items.add(address);
    return Ok(address);
  }

  @override
  Future<Result<void>> delete(String addressId) async {
    items.removeWhere((item) => item.id == addressId);
    return const Ok(null);
  }
}
