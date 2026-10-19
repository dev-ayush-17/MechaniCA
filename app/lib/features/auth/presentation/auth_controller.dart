import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../composition/providers.dart';
import '../domain/auth_service.dart';

class AuthState {
  const AuthState({this.session, this.isLoading = false, this.error});

  final Session? session;
  final bool isLoading;

  /// Safe to show to the user.
  final String? error;

  bool get isLoggedIn => session != null;
}

/// Drives the login flow through the [AuthService] port.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._service) : super(const AuthState());

  final AuthService _service;

  /// The screens collect 10 digits; the port takes E.164.
  static String toE164(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
    return digits.startsWith('+') ? digits : '+91$digits';
  }

  Future<bool> sendOtp(String phone) async {
    state = AuthState(session: state.session, isLoading: true);
    final result = await _service.requestOtp(toE164(phone));
    return result.when(
      onOk: (_) {
        state = AuthState(session: state.session);
        return true;
      },
      onErr: (failure) {
        state = AuthState(session: state.session, error: failure.message);
        return false;
      },
    );
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    state = AuthState(session: state.session, isLoading: true);
    final result = await _service.verifyOtp(toE164(phone), otp);
    return result.when(
      onOk: (session) {
        state = AuthState(session: session);
        return true;
      },
      onErr: (failure) {
        state = AuthState(session: state.session, error: failure.message);
        return false;
      },
    );
  }

  Future<bool> loginWithGoogle() async {
    state = AuthState(session: state.session, isLoading: true);
    final result = await _service.signInWithGoogle();
    return result.when(
      onOk: (session) {
        state = AuthState(session: session);
        return true;
      },
      onErr: (failure) {
        state = AuthState(session: state.session, error: failure.message);
        return false;
      },
    );
  }

  Future<void> logout() async {
    final result = await _service.signOut();
    result.when(
      onOk: (_) => state = const AuthState(),
      onErr: (failure) =>
          state = AuthState(session: state.session, error: failure.message),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);
