import 'package:dio/dio.dart';

import '../../../core/api/generated/me/me_client.dart';
import '../../../core/api/generated/models/contact_out.dart';
import '../../../core/api/generated/models/create_contact_request.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/contact_api.dart';
import '../domain/emergency_contact.dart';

class HttpContactApi implements ContactApi {
  HttpContactApi({
    required MeClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final MeClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<List<EmergencyContact>>> list() async {
    try {
      final token = await _token();
      final body = await _client.listContactsV1MeContactsGet(
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(body.items.map(_fromOut).toList());
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<EmergencyContact>> create({
    required String name,
    required String phone,
  }) async {
    try {
      final token = await _token();
      final body = await _client.createContactV1MeContactsPost(
        body: CreateContactRequest(name: name, phone: phone),
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(_fromOut(body));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<void>> delete(String contactId) async {
    try {
      final token = await _token();
      await _client.deleteContactV1MeContactsContactIdDelete(
        contactId: contactId,
        authorization: token == null ? null : 'Bearer $token',
      );
      return const Ok(null);
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  EmergencyContact _fromOut(ContactOut item) => EmergencyContact(
        id: item.id,
        name: item.name,
        phoneE164: item.phoneE164,
      );
}
