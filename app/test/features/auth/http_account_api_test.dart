import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanica_app/core/api/generated/export.dart' as api;
import 'package:mechanica_app/core/error/result.dart';
import 'package:mechanica_app/features/auth/data/http_account_api.dart';
import 'package:mechanica_app/features/auth/domain/account_api.dart';
import 'package:mechanica_app/features/auth/domain/auth_service.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._respond);

  final ResponseBody Function(RequestOptions options, int call) _respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _respond(options, requests.length);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, Object?> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, Object?> _user() => {
      'id': 'uid_1',
      'role': 'customer',
      'name': 'Asha',
      'phoneE164': '+919876543210',
      'status': 'active',
      'createdAt': '2026-10-19T08:00:00Z',
      'updatedAt': '2026-10-19T08:00:00Z',
    };

Map<String, Object?> _error(String code) => {
      'error': {
        'code': code,
        'message': 'Message for $code',
        'fields': {},
        'requestId': 'r1'
      },
    };

class _RefreshingAuth implements AuthService {
  int refreshes = 0;

  @override
  Future<Session?> currentSession({bool forceRefresh = false}) async {
    if (forceRefresh) refreshes++;
    return Session(
      userId: 'uid_1',
      idToken: 'refreshed-token',
      expiresAt: DateTime.utc(2026, 10, 19, 9),
      role: 'customer',
    );
  }

  @override
  Future<Result<void>> requestOtp(String phoneE164) =>
      throw UnimplementedError();

  @override
  Future<Result<Session>> verifyOtp(String phoneE164, String code) =>
      throw UnimplementedError();

  @override
  Future<Result<Session>> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<Result<void>> signOut() => throw UnimplementedError();
}

final _session = Session(
  userId: 'uid_1',
  idToken: 'old-token',
  expiresAt: DateTime.utc(2026, 10, 19, 8),
  role: 'customer',
);

(HttpAccountApi, _StubAdapter, _RefreshingAuth) _build(
  ResponseBody Function(RequestOptions, int) respond,
) {
  final adapter = _StubAdapter(respond);
  final dio = Dio()..httpClientAdapter = adapter;
  final auth = _RefreshingAuth();
  final client = api.RestClient(dio, baseUrl: 'http://api.test');
  return (HttpAccountApi(client: client, auth: auth), adapter, auth);
}

void main() {
  test('bootstrap_sends_intent_with_bearer_and_no_role', () async {
    final (accounts, adapter, _) = _build((_, __) => _json(201, _user()));

    final result = await accounts.bootstrap(
      _session,
      intent: AccountIntent.customer,
      name: 'Asha',
    );

    final request = adapter.requests.single;
    expect(request.path, '/v1/me/bootstrap');
    expect(request.headers['authorization'], 'Bearer old-token');
    expect(request.data, {'intent': 'customer', 'name': 'Asha'});
    expect(result.when(onOk: (a) => a.phoneE164, onErr: (_) => null),
        '+919876543210');
  });

  test('unauthenticated_refreshes_the_token_once_and_retries', () async {
    final (accounts, adapter, auth) = _build(
      (_, call) => call == 1
          ? _json(401, _error('unauthenticated'))
          : _json(200, _user()),
    );

    final result = await accounts.me(_session);

    expect(result, isA<Ok<Account>>());
    expect(auth.refreshes, 1);
    expect(adapter.requests.length, 2);
    expect(adapter.requests.last.headers['authorization'],
        'Bearer refreshed-token');
  });

  test('second_401_gives_up_so_the_caller_signs_out', () async {
    final (accounts, adapter, auth) = _build(
      (_, __) => _json(401, _error('unauthenticated')),
    );

    final result = await accounts.me(_session);

    expect((result as Err).failure, isA<Unauthenticated>());
    expect(auth.refreshes, 1);
    expect(adapter.requests.length, 2);
  });

  test('role_exists_maps_to_conflict', () async {
    final (accounts, _, _) =
        _build((_, __) => _json(409, _error('role_exists')));

    final result =
        await accounts.bootstrap(_session, intent: AccountIntent.mechanic);

    final failure = (result as Err).failure as Conflict;
    expect(failure.code, 'role_exists');
  });

  test('unreachable_server_is_unavailable', () async {
    final (accounts, _, _) = _build(
      (options, _) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      ),
    );

    final result = await accounts.me(_session);

    expect((result as Err).failure, isA<Unavailable>());
  });
}
