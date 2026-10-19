// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'fallback/fallback_client.dart';
import 'admin/admin_client.dart';
import 'bookings/bookings_client.dart';
import 'catalog/catalog_client.dart';
import 'coupons/coupons_client.dart';
import 'internal/internal_client.dart';
import 'me/me_client.dart';
import 'mechanic/mechanic_client.dart';
import 'payments/payments_client.dart';
import 'quotes/quotes_client.dart';
import 'uploads/uploads_client.dart';
import 'vehicles/vehicles_client.dart';
import 'wallet/wallet_client.dart';

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
  BookingsClient? _bookings;
  CatalogClient? _catalog;
  CouponsClient? _coupons;
  InternalClient? _internal;
  MeClient? _me;
  MechanicClient? _mechanic;
  PaymentsClient? _payments;
  QuotesClient? _quotes;
  UploadsClient? _uploads;
  VehiclesClient? _vehicles;
  WalletClient? _wallet;

  FallbackClient get fallback => _fallback ??= FallbackClient(_dio, baseUrl: _baseUrl);

  AdminClient get admin => _admin ??= AdminClient(_dio, baseUrl: _baseUrl);

  BookingsClient get bookings => _bookings ??= BookingsClient(_dio, baseUrl: _baseUrl);

  CatalogClient get catalog => _catalog ??= CatalogClient(_dio, baseUrl: _baseUrl);

  CouponsClient get coupons => _coupons ??= CouponsClient(_dio, baseUrl: _baseUrl);

  InternalClient get internal => _internal ??= InternalClient(_dio, baseUrl: _baseUrl);

  MeClient get me => _me ??= MeClient(_dio, baseUrl: _baseUrl);

  MechanicClient get mechanic => _mechanic ??= MechanicClient(_dio, baseUrl: _baseUrl);

  PaymentsClient get payments => _payments ??= PaymentsClient(_dio, baseUrl: _baseUrl);

  QuotesClient get quotes => _quotes ??= QuotesClient(_dio, baseUrl: _baseUrl);

  UploadsClient get uploads => _uploads ??= UploadsClient(_dio, baseUrl: _baseUrl);

  VehiclesClient get vehicles => _vehicles ??= VehiclesClient(_dio, baseUrl: _baseUrl);

  WalletClient get wallet => _wallet ??= WalletClient(_dio, baseUrl: _baseUrl);
}
