// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/application_request.dart';
import '../models/availability_request.dart';
import '../models/earnings_list_out.dart';
import '../models/mechanic_out.dart';

part 'mechanic_client.g.dart';

@RestApi()
abstract class MechanicClient {
  factory MechanicClient(Dio dio, {String? baseUrl}) = _MechanicClient;

  /// Get Mechanic Profile
  @GET('/v1/mechanic')
  Future<MechanicOut> getMechanicProfileV1MechanicGet({
    @Header('authorization') String? authorization,
  });

  /// Submit Application
  @POST('/v1/mechanic/application')
  Future<MechanicOut> submitApplicationV1MechanicApplicationPost({
    @Body() required ApplicationRequest body,
    @Header('authorization') String? authorization,
  });

  /// Set Availability
  @POST('/v1/mechanic/availability')
  Future<MechanicOut> setAvailabilityV1MechanicAvailabilityPost({
    @Body() required AvailabilityRequest body,
    @Header('authorization') String? authorization,
  });

  /// List Mechanic Earnings
  @GET('/v1/mechanic/earnings')
  Future<EarningsListOut> listMechanicEarningsV1MechanicEarningsGet({
    @Header('authorization') String? authorization,
  });

  /// Heartbeat
  @POST('/v1/mechanic/heartbeat')
  Future<MechanicOut> heartbeatV1MechanicHeartbeatPost({
    @Header('authorization') String? authorization,
  });
}
