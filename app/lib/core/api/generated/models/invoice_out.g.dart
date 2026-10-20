// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceOut _$InvoiceOutFromJson(Map<String, dynamic> json) => InvoiceOut(
      bookingId: json['bookingId'] as String,
      cgstPaise: (json['cgstPaise'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      customerName: json['customerName'] as String,
      downloadUrl: json['downloadUrl'] as String,
      gstin: json['gstin'] as String,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => InvoiceLineOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      mechanicDisplayName: json['mechanicDisplayName'] as String,
      number: json['number'] as String,
      paymentMethod: json['paymentMethod'] as String,
      sgstPaise: (json['sgstPaise'] as num).toInt(),
      totalPaise: (json['totalPaise'] as num).toInt(),
      vehicleRegistration: json['vehicleRegistration'] as String,
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$InvoiceOutToJson(InvoiceOut instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'cgstPaise': instance.cgstPaise,
      'createdAt': instance.createdAt.toIso8601String(),
      'customerName': instance.customerName,
      'downloadUrl': instance.downloadUrl,
      'gstin': instance.gstin,
      'lines': instance.lines,
      'mechanicDisplayName': instance.mechanicDisplayName,
      'number': instance.number,
      'paymentMethod': instance.paymentMethod,
      'sgstPaise': instance.sgstPaise,
      'totalPaise': instance.totalPaise,
      'vehicleRegistration': instance.vehicleRegistration,
      'version': instance.version,
    };
