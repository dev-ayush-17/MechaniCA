// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'fallback/fallback_client.dart';
import 'admin/admin_client.dart';
import 'me/me_client.dart';
import 'mechanic/mechanic_client.dart';
import 'uploads/uploads_client.dart';

/// MechUpp API `v0.1.0`
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.1.0';

  FallbackClient? _fallback;
  AdminClient? _admin;
  MeClient? _me;
  MechanicClient? _mechanic;
  UploadsClient? _uploads;

  FallbackClient get fallback => _fallback ??= FallbackClient(_dio, baseUrl: _baseUrl);

  AdminClient get admin => _admin ??= AdminClient(_dio, baseUrl: _baseUrl);

  MeClient get me => _me ??= MeClient(_dio, baseUrl: _baseUrl);

  MechanicClient get mechanic => _mechanic ??= MechanicClient(_dio, baseUrl: _baseUrl);

  UploadsClient get uploads => _uploads ??= UploadsClient(_dio, baseUrl: _baseUrl);
}
