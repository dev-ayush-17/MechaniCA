import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/generated/export.dart' as api;
import '../../../core/error/result.dart';
import '../domain/account_api.dart';
import '../domain/auth_service.dart';

/// [AccountApi] over the generated OpenAPI client. Generated types stop here;
/// widgets and use cases only see [Account] and [AppFailure].
class HttpAccountApi implements AccountApi {
  HttpAccountApi({required api.RestClient client, required AuthService auth})
      : _client = client,
        _auth = auth;

  final api.RestClient _client;
  final AuthService _auth;

  @override
  Future<Result<Account>> bootstrap(
    Session session, {
    required AccountIntent intent,
    String? name,
  }) {
    return _call(session, (token) async {
      final user = await _client.me.bootstrapV1MeBootstrapPost(
        body: api.BootstrapRequest(
          intent: intent == AccountIntent.mechanic
              ? api.Intent.mechanic
              : api.Intent.customer,
          name: name,
        ),
        authorization: 'Bearer $token',
      );
      return _toAccount(user);
    });
  }

  @override
  Future<Result<Account>> me(Session session) {
    return _call(session, (token) async {
      final user = await _client.me.meV1MeGet(authorization: 'Bearer $token');
      return _toAccount(user);
    });
  }

  @override
  Future<Result<Account>> update(
    Session session, {
    required String name,
    String? email,
  }) {
    return _call(session, (token) async {
      final user = await _client.me.patchMeV1MePatch(
        body: api.PatchMeRequest(name: name, email: email),
        authorization: 'Bearer $token',
      );
      return _toAccount(user);
    });
  }

  /// Runs [request]. On 401 it refreshes the token once and retries; if that
  /// also fails the caller gets [Unauthenticated] and signs out locally.
  Future<Result<Account>> _call(
    Session session,
    Future<Account> Function(String token) request,
  ) async {
    try {
      return Ok(await request(session.idToken));
    } on DioException catch (e) {
      debugPrint('HttpAccountApi DioException: $e');
      debugPrint('DioException type: ${e.type}, message: ${e.message}, error: ${e.error}');
      debugPrint('DioException request: ${e.requestOptions.uri}, data: ${e.requestOptions.data}');
      final failure = failureFromDio(e);
      if (failure is! Unauthenticated) return Err(failure);
      final refreshed = await _auth.currentSession(forceRefresh: true);
      if (refreshed == null) return Err(failure);
      try {
        return Ok(await request(refreshed.idToken));
      } on DioException catch (retry) {
        debugPrint('HttpAccountApi retry DioException: $retry');
        return Err(failureFromDio(retry));
      }
    }
  }

  Account _toAccount(api.UserOut user) => Account(
        id: user.id,
        role: user.role,
        name: user.name,
        phoneE164: user.phoneE164,
        email: user.email,
      );
}

/// Maps the API error envelope (docs/prd/12-api-contracts.md) to [AppFailure].
AppFailure failureFromDio(DioException e) {
  final response = e.response;
  if (response == null) {
    return const Unavailable(
        'Could not reach the server. Check your connection.');
  }
  final body = response.data;
  final error = body is Map<String, dynamic> ? body['error'] : null;
  if (error is! Map<String, dynamic>) {
    return const Unavailable();
  }
  final code = error['code'] as String? ?? 'internal';
  final message =
      error['message'] as String? ?? 'Something went wrong. Try again.';
  final rawFields = error['fields'];
  final fields = rawFields is Map<String, dynamic>
      ? rawFields.map((k, v) => MapEntry(k, v.toString()))
      : const <String, String>{};
  return switch (code) {
    'unauthenticated' => Unauthenticated(message),
    'permission_denied' || 'account_suspended' => PermissionDenied(message),
    'not_found' => NotFound(message),
    'invalid_input' => InvalidInput(message, fields: fields),
    'rate_limited' => RateLimited(message),
    'unavailable' => Unavailable(message),
    _ when response.statusCode == 409 => Conflict(message, code: code),
    _ => Unavailable(message),
  };
}
