// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/address_list_out.dart';
import '../models/address_out.dart';
import '../models/create_address_request.dart';
import '../models/patch_address_request.dart';

part 'addresses_client.g.dart';

@RestApi()
abstract class AddressesClient {
  factory AddressesClient(Dio dio, {String? baseUrl}) = _AddressesClient;

  /// List Addresses
  @GET('/v1/addresses')
  Future<AddressListOut> listAddressesV1AddressesGet({
    @Header('authorization') String? authorization,
  });

  /// Create Address
  @POST('/v1/addresses')
  Future<AddressOut> createAddressV1AddressesPost({
    @Body() required CreateAddressRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
    @Header('authorization') String? authorization,
  });

  /// Delete Address
  @DELETE('/v1/addresses/{address_id}')
  Future<void> deleteAddressV1AddressesAddressIdDelete({
    @Path('address_id') required String addressId,
    @Header('authorization') String? authorization,
  });

  /// Patch Address
  @PATCH('/v1/addresses/{address_id}')
  Future<AddressOut> patchAddressV1AddressesAddressIdPatch({
    @Path('address_id') required String addressId,
    @Body() required PatchAddressRequest body,
    @Header('authorization') String? authorization,
  });
}
