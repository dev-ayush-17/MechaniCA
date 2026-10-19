// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/sign_upload_out.dart';
import '../models/sign_upload_request.dart';

part 'uploads_client.g.dart';

@RestApi()
abstract class UploadsClient {
  factory UploadsClient(Dio dio, {String? baseUrl}) = _UploadsClient;

  /// Sign Upload
  @POST('/v1/uploads/sign')
  Future<SignUploadOut> signUploadV1UploadsSignPost({
    @Body() required SignUploadRequest body,
    @Header('authorization') String? authorization,
  });
}
