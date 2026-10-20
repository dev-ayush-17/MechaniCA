import '../../../core/error/result.dart';
import '../domain/invoice.dart';
import '../domain/invoice_api.dart';

class FakeInvoiceApi implements InvoiceApi {
  FakeInvoiceApi({Map<String, Invoice>? invoices, this.demoFallback = false})
      : invoices = invoices ?? {};

  final Map<String, Invoice> invoices;
  final bool demoFallback;
  final Map<String, List<int>> pdfs = {};

  @override
  Future<Result<Invoice>> get(String bookingId) async {
    final invoice = invoices[bookingId];
    if (invoice != null) return Ok(invoice);
    if (!demoFallback || bookingId.isEmpty) {
      return const Err(NotFound('We could not find that invoice.'));
    }
    return Ok(
      Invoice(
        bookingId: bookingId,
        number: 'MC-202606-000001',
        version: 1,
        totalPaise: 76464,
        cgstPaise: 5832,
        sgstPaise: 5832,
        gstin: '22AAAAA0000A1Z5',
        customerName: 'Priya Sharma',
        vehicleRegistration: 'BR01AB1234',
        mechanicDisplayName: 'Imran',
        paymentMethod: 'upi',
        downloadUrl: 'https://storage.fake/download/invoices/$bookingId/v1.pdf',
        createdAt: DateTime.utc(2026, 6, 1, 10),
        lines: const [
          InvoiceLine(name: 'General Service', quantity: 1, amountPaise: 59900),
          InvoiceLine(name: 'Convenience fee', quantity: 1, amountPaise: 4900),
        ],
      ),
    );
  }

  @override
  Future<Result<List<int>>> downloadPdf(String bookingId) async {
    final invoice = invoices[bookingId];
    if (invoice == null) {
      return const Err(NotFound('We could not find that invoice.'));
    }
    return Ok(pdfs[bookingId] ?? _minimalPdf);
  }
}

/// Tiny valid-looking PDF for demo and widget tests.
const _minimalPdf = <int>[
  37, 80, 68, 70, 45, 49, 46, 52, 10, 37, 226, 227, 207, 211, 10,
];
