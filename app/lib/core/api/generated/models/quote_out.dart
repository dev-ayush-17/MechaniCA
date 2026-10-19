// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'quote_out.g.dart';

@JsonSerializable()
class QuoteOut {
  const QuoteOut({
    required this.cgstPaise,
    required this.discountPaise,
    required this.feePaise,
    required this.laborPaise,
    required this.partsPaise,
    required this.sgstPaise,
    required this.totalPaise,
  });
  
  factory QuoteOut.fromJson(Map<String, Object?> json) => _$QuoteOutFromJson(json);
  
  final int cgstPaise;
  final int discountPaise;
  final int feePaise;
  final int laborPaise;
  final int partsPaise;
  final int sgstPaise;
  final int totalPaise;

  Map<String, Object?> toJson() => _$QuoteOutToJson(this);
}
