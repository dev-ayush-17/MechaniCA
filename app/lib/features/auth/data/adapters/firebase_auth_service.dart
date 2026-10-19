import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/result.dart';
import '../../../../core/time/clock.dart';
import '../../domain/auth_service.dart';

/// [AuthService] over Firebase Auth phone sign-in. This is the only file in
/// the auth feature that imports the Firebase SDK.
///
/// Firebase initializes lazily on first use, so the fake binding never loads it.
/// The SDK keeps the session in platform secure storage; we do not copy tokens.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({required AppConfig config, required Clock clock})
      : _config = config,
        _clock = clock;

  static const _emulatorAuthPort = 9099;

  final AppConfig _config;
  final Clock _clock;

  fb.FirebaseAuth? _auth;
  String? _verificationId;
  int? _resendToken;

  Future<fb.FirebaseAuth> _ensureAuth() async {
    final existing = _auth;
    if (existing != null) return existing;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    final auth = fb.FirebaseAuth.instance;
    if (_config.useFirebaseEmulator && !_config.isProd) {
      await auth.useAuthEmulator(
          _config.firebaseEmulatorHost, _emulatorAuthPort);
    }
    return _auth = auth;
  }

  @override
  Future<Result<void>> requestOtp(String phoneE164) async {
    final fb.FirebaseAuth auth;
    try {
      auth = await _ensureAuth();
    } on FirebaseException catch (e) {
      return Err(mapFirebaseAuthError(e));
    }

    final done = Completer<Result<void>>();
    await auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {
        // Android may read the SMS itself. The user still types the code, which
        // keeps one sign-in path.
      },
      verificationFailed: (e) {
        if (!done.isCompleted) done.complete(Err(mapFirebaseAuthError(e)));
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!done.isCompleted) done.complete(const Ok(null));
      },
      codeAutoRetrievalTimeout: (verificationId) =>
          _verificationId ??= verificationId,
    );
    if (!done.isCompleted) done.complete(const Ok(null));
    return done.future;
  }

  @override
  Future<Result<Session>> verifyOtp(String phoneE164, String code) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      return const Err(InvalidInput('Request a new code.'));
    }
    try {
      final auth = await _ensureAuth();
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      final signedIn = await auth.signInWithCredential(credential);
      final user = signedIn.user;
      if (user == null) return const Err(Unauthenticated());
      _verificationId = null;
      return Ok(await _toSession(user, forceRefresh: false));
    } on FirebaseException catch (e) {
      return Err(mapFirebaseAuthError(e));
    }
  }

  @override
  Future<Result<Session>> signInWithGoogle() async =>
      const Err(Unavailable('provider_disabled'));

  @override
  Future<Result<void>> signOut() async {
    try {
      final auth = await _ensureAuth();
      await auth.signOut();
      _verificationId = null;
      _resendToken = null;
      return const Ok(null);
    } on FirebaseException catch (e) {
      return Err(mapFirebaseAuthError(e));
    }
  }

  @override
  Future<Session?> currentSession({bool forceRefresh = false}) async {
    try {
      final auth = await _ensureAuth();
      final user = auth.currentUser;
      if (user == null) return null;
      return _toSession(user, forceRefresh: forceRefresh);
    } on FirebaseException {
      // Offline or misconfigured: treat as signed out and let the user retry.
      return null;
    }
  }

  Future<Session> _toSession(fb.User user, {required bool forceRefresh}) async {
    final result = await user.getIdTokenResult(forceRefresh);
    return Session(
      userId: user.uid,
      idToken: result.token ?? '',
      expiresAt: result.expirationTime ??
          _clock.now().add(const Duration(minutes: 55)),
      role: result.claims?['role'] as String? ?? 'customer',
    );
  }
}

/// Maps SDK error codes to our failures. Messages are safe to show.
@visibleForTesting
AppFailure mapFirebaseAuthError(FirebaseException e) {
  return switch (e.code) {
    'invalid-verification-code' ||
    'invalid-verification-id' =>
      const InvalidInput('That code is incorrect.'),
    'session-expired' ||
    'code-expired' =>
      const InvalidInput('That code has expired. Request a new one.'),
    'invalid-phone-number' => const InvalidInput('Enter valid mobile number'),
    'too-many-requests' ||
    'quota-exceeded' =>
      const RateLimited('Too many attempts. Try again later.'),
    'network-request-failed' => const Unavailable(),
    'user-disabled' => const PermissionDenied('This account is disabled.'),
    _ => const Unavailable('Sign-in is unavailable. Try again.'),
  };
}
