import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> saveInvoicePdf(String bookingId, List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/invoice-$bookingId.pdf');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<void> shareInvoicePdf(String path) async {
  await SharePlus.instance.share(
    ShareParams(files: [XFile(path, mimeType: 'application/pdf')]),
  );
}
