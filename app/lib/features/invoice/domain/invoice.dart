class Invoice {
  const Invoice({
    required this.bookingId,
    required this.number,
    required this.version,
    required this.totalPaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.gstin,
    required this.customerName,
    required this.vehicleRegistration,
    required this.mechanicDisplayName,
    required this.paymentMethod,
    required this.downloadUrl,
    required this.createdAt,
    required this.lines,
  });

  final String bookingId;
  final String number;
  final int version;
  final int totalPaise;
  final int cgstPaise;
  final int sgstPaise;
  final String gstin;
  final String customerName;
  final String vehicleRegistration;
  final String mechanicDisplayName;
  final String paymentMethod;
  final String downloadUrl;
  final DateTime createdAt;
  final List<InvoiceLine> lines;

  int get gstPaise => cgstPaise + sgstPaise;
}

class InvoiceLine {
  const InvoiceLine({
    required this.name,
    required this.quantity,
    required this.amountPaise,
  });

  final String name;
  final int quantity;
  final int amountPaise;
}
