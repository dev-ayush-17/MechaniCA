import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../composition/providers.dart';
import '../domain/account_api.dart';
import '../domain/auth_service.dart';

class AuthState {
  const AuthState({
    this.session,
    this.account,
    this.isLoading = false,
    this.error,
  });

  final Session? session;
  final Account? account;
  final bool isLoading;

  /// Safe to show to the user.
  final String? error;

  bool get isLoggedIn => session != null;
}

/// Drives the login flow through the [AuthService] and [AccountApi] ports.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(
    this._service,
    this._accounts, {
    this.intent = AccountIntent.customer,
  }) : super(const AuthState());

  final AuthService _service;
  final AccountApi _accounts;

  /// The customer app signs in as a customer; the mechanic entrypoint passes mechanic.
  final AccountIntent intent;

  /// The screens collect 10 digits; the port takes E.164.
  static String toE164(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
    return digits.startsWith('+') ? digits : '+91$digits';
  }

  Future<bool> sendOtp(String phone) async {
    state = const AuthState(isLoading: true);
    final result = await _service.requestOtp(toE164(phone));
    return result.when(
      onOk: (_) {
        state = const AuthState();
        return true;
      },
      onErr: (failure) {
        state = AuthState(error: failure.message);
        return false;
      },
    );
  }

  /// Verifies the code, then bootstraps the account. If the bootstrap fails the
  /// local session is dropped so the next attempt starts clean (the call is
  /// idempotent on the server).
  Future<bool> verifyOtp(String phone, String otp) async {
    state = const AuthState(isLoading: true);
    final verified = await _service.verifyOtp(toE164(phone), otp);
    final session = verified.when(onOk: (s) => s, onErr: (_) => null);
    if (session == null) {
      state = AuthState(
        error: verified.when(onOk: (_) => null, onErr: (f) => f.message),
      );
      return false;
    }
    return _completeSignIn(session);
  }

  Future<bool> loginWithGoogle() async {
    state = const AuthState(isLoading: true);
    final result = await _service.signInWithGoogle();
    final session = result.when(onOk: (s) => s, onErr: (_) => null);
    if (session == null) {
      state = AuthState(
        error: result.when(onOk: (_) => null, onErr: (f) => f.message),
      );
      return false;
    }
    return _completeSignIn(session);
  }

  Future<bool> _completeSignIn(Session session) async {
    final boot = await _accounts.bootstrap(session, intent: intent);
    return boot.when(
      onOk: (account) async {
        // The bootstrap sets the role claim; fetch a token that carries it.
        final fresh = await _service.currentSession(forceRefresh: true);
        state = AuthState(session: fresh ?? session, account: account);
        return true;
      },
      onErr: (failure) async {
        await _service.signOut();
        state = AuthState(error: failure.message);
        return false;
      },
    );
  }

  Future<void> logout() async {
    final result = await _service.signOut();
    result.when(
      onOk: (_) => state = const AuthState(),
      onErr: (failure) => state = AuthState(
        session: state.session,
        account: state.account,
        error: failure.message,
      ),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(accountApiProvider),
  ),
);
