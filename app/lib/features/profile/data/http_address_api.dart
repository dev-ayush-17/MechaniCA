import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/generated/addresses/addresses_client.dart';
import '../../../core/api/generated/models/address_out.dart';
import '../../../core/api/generated/models/create_address_request.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/address_api.dart';
import '../domain/saved_address.dart';

class HttpAddressApi implements AddressApi {
  HttpAddressApi({
    required AddressesClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final AddressesClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<List<SavedAddress>>> list() async {
    try {
      final token = await _token();
      final body = await _client.listAddressesV1AddressesGet(
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(body.items.map(_fromOut).toList());
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

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
    try {
      final token = await _token();
      final body = await _client.createAddressV1AddressesPost(
        body: CreateAddressRequest(
          label: label,
          line1: line1,
          city: city,
          pincode: pincode,
          lat: lat,
          lng: lng,
          landmark: landmark,
          isDefault: isDefault,
        ),
        idempotencyKey: const Uuid().v4(),
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(_fromOut(body));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<void>> delete(String addressId) async {
    try {
      final token = await _token();
      await _client.deleteAddressV1AddressesAddressIdDelete(
        addressId: addressId,
        authorization: token == null ? null : 'Bearer $token',
      );
      return const Ok(null);
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  SavedAddress _fromOut(AddressOut item) => SavedAddress(
        id: item.id,
        label: item.label,
        line1: item.line1,
        city: item.city,
        pincode: item.pincode,
        lat: item.lat.toDouble(),
        lng: item.lng.toDouble(),
        isDefault: item.isDefault,
        landmark: item.landmark,
      );
}
