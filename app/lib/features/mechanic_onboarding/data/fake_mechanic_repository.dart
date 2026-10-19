import '../../../core/error/result.dart';
import '../domain/mechanic_repository.dart';

/// Offline mechanic onboarding for dev without a running API.
class FakeMechanicRepository implements MechanicRepository {
  MechanicProfile? _profile;

  @override
  Future<Result<MechanicProfile>> getProfile(String idToken) async {
    _profile ??= const MechanicProfile(
      id: 'fake_mechanic',
      displayName: '',
      photoPath: '',
      yearsExperience: 0,
      languages: [],
      serviceArea: null,
      verified: false,
      verificationStatus: VerificationStatus.draft,
      online: false,
    );
    return Ok(_profile!);
  }

  @override
  Future<Result<MechanicProfile>> submitApplication(
    String idToken,
    ApplicationInput input,
  ) async {
    if (input.displayName.trim().length < 2) {
      return const Err(InvalidInput('Display name must be 2–40 characters.'));
    }
    _profile = MechanicProfile(
      id: 'fake_mechanic',
      displayName: input.displayName.trim(),
      photoPath: input.photoPath,
      yearsExperience: input.yearsExperience,
      languages: input.languages,
      serviceArea: input.serviceArea,
      verified: false,
      verificationStatus: VerificationStatus.pending,
      online: false,
    );
    return Ok(_profile!);
  }

  @override
  Future<Result<MechanicProfile>> setAvailability(
    String idToken, {
    required bool online,
  }) async {
    final current = _profile;
    if (current == null) {
      return const Err(NotFound('Finish mechanic setup first.'));
    }
    if (online && !current.canGoOnline) {
      return const Err(InvalidInput('Get verified before going online.'));
    }
    _profile = MechanicProfile(
      id: current.id,
      displayName: current.displayName,
      photoPath: current.photoPath,
      yearsExperience: current.yearsExperience,
      languages: current.languages,
      serviceArea: current.serviceArea,
      verified: current.verified,
      verificationStatus: current.verificationStatus,
      online: online,
      rejectionReason: current.rejectionReason,
    );
    return Ok(_profile!);
  }

  /// Test helper: mark the fake mechanic verified.
  void approveForDemo() {
    final current = _profile;
    if (current == null) return;
    _profile = MechanicProfile(
      id: current.id,
      displayName: current.displayName,
      photoPath: current.photoPath,
      yearsExperience: current.yearsExperience,
      languages: current.languages,
      serviceArea: current.serviceArea,
      verified: true,
      verificationStatus: VerificationStatus.approved,
      online: current.online,
    );
  }

  @override
  Future<Result<SignedUpload>> signUpload(
    String idToken, {
    required String path,
    required String contentType,
    required int maxBytes,
  }) async {
    if (path.contains('..')) {
      return const Err(InvalidInput('That path is not allowed.'));
    }
    return Ok(SignedUpload(uploadUrl: 'https://storage.fake/$path', path: path));
  }
}
