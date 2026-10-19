import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../composition/providers.dart';
import '../domain/mechanic_repository.dart';

class MechanicState {
  const MechanicState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  final MechanicProfile? profile;
  final bool isLoading;
  final String? error;
}

class MechanicNotifier extends StateNotifier<MechanicState> {
  MechanicNotifier(this._repo, this._readSession) : super(const MechanicState());

  final MechanicRepository _repo;
  final Future<String?> Function() _readSession;

  Future<void> refresh() async {
    final token = await _readSession();
    if (token == null) return;
    state = const MechanicState(isLoading: true);
    final result = await _repo.getProfile(token);
    state = result.when(
      onOk: (profile) => MechanicState(profile: profile),
      onErr: (f) => MechanicState(error: f.message),
    );
  }

  Future<bool> submit(ApplicationInput input) async {
    final token = await _readSession();
    if (token == null) return false;
    state = MechanicState(profile: state.profile, isLoading: true);
    final result = await _repo.submitApplication(token, input);
    return result.when(
      onOk: (profile) {
        state = MechanicState(profile: profile);
        return true;
      },
      onErr: (f) {
        state = MechanicState(profile: state.profile, error: f.message);
        return false;
      },
    );
  }

  Future<bool> setOnline(bool online) async {
    final token = await _readSession();
    if (token == null) return false;
    final result = await _repo.setAvailability(token, online: online);
    return result.when(
      onOk: (profile) {
        state = MechanicState(profile: profile);
        return true;
      },
      onErr: (f) {
        state = MechanicState(profile: state.profile, error: f.message);
        return false;
      },
    );
  }
}

final mechanicProvider = StateNotifierProvider<MechanicNotifier, MechanicState>(
  (ref) {
    final auth = ref.watch(authServiceProvider);
    return MechanicNotifier(
      ref.watch(mechanicRepositoryProvider),
      () async => (await auth.currentSession())?.idToken,
    );
  },
);
