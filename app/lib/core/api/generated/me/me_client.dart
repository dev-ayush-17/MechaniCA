// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/bootstrap_request.dart';
import '../models/user_out.dart';

part 'me_client.g.dart';

@RestApi()
abstract class MeClient {
  factory MeClient(Dio dio, {String? baseUrl}) = _MeClient;

  /// Bootstrap.
  ///
  /// Create the caller's user document on first sign-in. Safe to repeat.
  @POST('/v1/me/bootstrap')
  Future<UserOut> bootstrapV1MeBootstrapPost({
    @Body() required BootstrapRequest body,
    @Header('authorization') String? authorization,
  });

  /// Me
  @GET('/v1/me')
  Future<UserOut> meV1MeGet({
    @Header('authorization') String? authorization,
  });
}
