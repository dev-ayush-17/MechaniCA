// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/bootstrap_request.dart';
import '../models/contact_list_out.dart';
import '../models/contact_out.dart';
import '../models/create_contact_request.dart';
import '../models/device_out.dart';
import '../models/patch_me_request.dart';
import '../models/register_device_request.dart';
import '../models/user_out.dart';

part 'me_client.g.dart';

@RestApi()
abstract class MeClient {
  factory MeClient(Dio dio, {String? baseUrl}) = _MeClient;

  /// Me
  @GET('/v1/me')
  Future<UserOut> meV1MeGet({
    @Header('authorization') String? authorization,
  });

  /// Patch Me
  @PATCH('/v1/me')
  Future<UserOut> patchMeV1MePatch({
    @Body() required PatchMeRequest body,
    @Header('authorization') String? authorization,
  });

  /// Bootstrap.
  ///
  /// Create the caller's user document on first sign-in. Safe to repeat.
  @POST('/v1/me/bootstrap')
  Future<UserOut> bootstrapV1MeBootstrapPost({
    @Body() required BootstrapRequest body,
    @Header('authorization') String? authorization,
  });

  /// List Contacts
  @GET('/v1/me/contacts')
  Future<ContactListOut> listContactsV1MeContactsGet({
    @Header('authorization') String? authorization,
  });

  /// Create Contact
  @POST('/v1/me/contacts')
  Future<ContactOut> createContactV1MeContactsPost({
    @Body() required CreateContactRequest body,
    @Header('authorization') String? authorization,
  });

  /// Delete Contact
  @DELETE('/v1/me/contacts/{contact_id}')
  Future<void> deleteContactV1MeContactsContactIdDelete({
    @Path('contact_id') required String contactId,
    @Header('authorization') String? authorization,
  });

  /// Register Device
  @POST('/v1/me/devices')
  Future<DeviceOut> registerDeviceV1MeDevicesPost({
    @Body() required RegisterDeviceRequest body,
    @Header('authorization') String? authorization,
  });
}
