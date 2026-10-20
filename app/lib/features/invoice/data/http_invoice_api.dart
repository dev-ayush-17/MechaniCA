import 'package:dio/dio.dart';

import '../../../core/api/generated/invoices/invoices_client.dart';
import '../../../core/api/generated/models/invoice_out.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/invoice.dart';
import '../domain/invoice_api.dart';

class HttpInvoiceApi implements InvoiceApi {
  HttpInvoiceApi({
    required InvoicesClient client,
    required Dio dio,
    required Future<String?> Function() token,
  })  : _client = client,
        _dio = dio,
        _token = token;

  final InvoicesClient _client;
  final Dio _dio;
  final Future<String?> Function() _token;

  @override
  Future<Result<Invoice>> get(String bookingId) async {
    try {
      final token = await _token();
      final body = await _client.getInvoiceV1InvoicesBookingIdGet(
        bookingId: bookingId,
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(_map(body));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<List<int>>> downloadPdf(String bookingId) async {
    final loaded = await get(bookingId);
    switch (loaded) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        try {
          final response = await _dio.get<List<int>>(
            value.downloadUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          final bytes = response.data;
          if (bytes == null || bytes.isEmpty) {
            return const Err(
              Unavailable('The invoice file could not be downloaded.'),
            );
          }
          return Ok(bytes);
        } on DioException catch (e) {
          return Err(failureFromDio(e));
        }
    }
  }

  Invoice _map(InvoiceOut body) => Invoice(
        bookingId: body.bookingId,
        number: body.number,
        version: body.version,
        totalPaise: body.totalPaise,
        cgstPaise: body.cgstPaise,
        sgstPaise: body.sgstPaise,
        gstin: body.gstin,
        customerName: body.customerName,
        vehicleRegistration: body.vehicleRegistration,
        mechanicDisplayName: body.mechanicDisplayName,
        paymentMethod: body.paymentMethod,
        downloadUrl: body.downloadUrl,
        createdAt: body.createdAt,
        lines: [
          for (final line in body.lines)
            InvoiceLine(
              name: line.name,
              quantity: line.quantity,
              amountPaise: line.amountPaise,
            ),
        ],
      );
}
