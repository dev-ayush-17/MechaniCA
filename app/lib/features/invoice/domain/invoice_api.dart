import '../../../core/error/result.dart';
import 'invoice.dart';

abstract class InvoiceApi {
  Future<Result<Invoice>> get(String bookingId);

  Future<Result<List<int>>> downloadPdf(String bookingId);
}
