// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'webhook_ack.g.dart';

@JsonSerializable()
class WebhookAck {
  const WebhookAck({
    this.ok = true,
  });
  
  factory WebhookAck.fromJson(Map<String, Object?> json) => _$WebhookAckFromJson(json);
  
  final bool ok;

  Map<String, Object?> toJson() => _$WebhookAckToJson(this);
}
