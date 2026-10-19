// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_vehicle_request.dart';
import '../models/patch_vehicle_request.dart';
import '../models/vehicle_list_out.dart';
import '../models/vehicle_out.dart';

part 'vehicles_client.g.dart';

@RestApi()
abstract class VehiclesClient {
  factory VehiclesClient(Dio dio, {String? baseUrl}) = _VehiclesClient;

  /// List Vehicles
  @GET('/v1/vehicles')
  Future<VehicleListOut> listVehiclesV1VehiclesGet({
    @Header('authorization') String? authorization,
  });

  /// Create Vehicle
  @POST('/v1/vehicles')
  Future<VehicleOut> createVehicleV1VehiclesPost({
    @Body() required CreateVehicleRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
    @Header('authorization') String? authorization,
  });

  /// Patch Vehicle
  @PATCH('/v1/vehicles/{vehicle_id}')
  Future<VehicleOut> patchVehicleV1VehiclesVehicleIdPatch({
    @Path('vehicle_id') required String vehicleId,
    @Body() required PatchVehicleRequest body,
    @Header('authorization') String? authorization,
  });

  /// Delete Vehicle
  @DELETE('/v1/vehicles/{vehicle_id}')
  Future<void> deleteVehicleV1VehiclesVehicleIdDelete({
    @Path('vehicle_id') required String vehicleId,
    @Header('authorization') String? authorization,
  });
}
