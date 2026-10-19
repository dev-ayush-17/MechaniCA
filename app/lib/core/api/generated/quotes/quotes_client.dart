// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/quote_out.dart';
import '../models/quote_request.dart';

part 'quotes_client.g.dart';

@RestApi()
abstract class QuotesClient {
  factory QuotesClient(Dio dio, {String? baseUrl}) = _QuotesClient;

  /// Create Quote
  @POST('/v1/quotes')
  Future<QuoteOut> createQuoteV1QuotesPost({
    @Body() required QuoteRequest body,
    @Header('authorization') String? authorization,
  });
}
