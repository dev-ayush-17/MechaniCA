// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/mechanic_out.dart';
import '../models/verification_request.dart';

part 'admin_client.g.dart';

@RestApi()
abstract class AdminClient {
  factory AdminClient(Dio dio, {String? baseUrl}) = _AdminClient;

  /// Decide Verification
  @POST('/v1/admin/mechanics/{mechanic_id}/verification')
  Future<MechanicOut> decideVerificationV1AdminMechanicsMechanicIdVerificationPost({
    @Path('mechanic_id') required String mechanicId,
    @Body() required VerificationRequest body,
    @Header('authorization') String? authorization,
  });
}
