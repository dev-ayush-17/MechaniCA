// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/chat_message_list_out.dart';
import '../models/chat_message_out.dart';
import '../models/masked_call_out.dart';
import '../models/send_message_request.dart';
import '../models/sign_chat_media_out.dart';
import '../models/sign_chat_media_request.dart';

part 'messages_client.g.dart';

@RestApi()
abstract class MessagesClient {
  factory MessagesClient(Dio dio, {String? baseUrl}) = _MessagesClient;

  /// Masked Call
  @POST('/v1/bookings/{booking_id}/masked-call')
  Future<MaskedCallOut> maskedCallV1BookingsBookingIdMaskedCallPost({
    @Path('booking_id') required String bookingId,
    @Header('authorization') String? authorization,
  });

  /// List Messages
  @GET('/v1/bookings/{booking_id}/messages')
  Future<ChatMessageListOut> listMessagesV1BookingsBookingIdMessagesGet({
    @Path('booking_id') required String bookingId,
    @Query('after') DateTime? after,
    @Header('authorization') String? authorization,
  });

  /// Send Message
  @POST('/v1/bookings/{booking_id}/messages')
  Future<ChatMessageOut> sendMessageV1BookingsBookingIdMessagesPost({
    @Path('booking_id') required String bookingId,
    @Body() required SendMessageRequest body,
    @Header('idempotency-key') String? idempotencyKey,
    @Header('authorization') String? authorization,
  });

  /// Sign Chat Media
  @POST('/v1/bookings/{booking_id}/messages/uploads')
  Future<SignChatMediaOut> signChatMediaV1BookingsBookingIdMessagesUploadsPost({
    @Path('booking_id') required String bookingId,
    @Body() required SignChatMediaRequest body,
    @Header('authorization') String? authorization,
  });
}
