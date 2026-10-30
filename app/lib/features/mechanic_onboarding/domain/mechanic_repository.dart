import '../../../core/error/result.dart';

enum MechanicDocumentKind { licence, governmentId, selfie }

enum VerificationStatus { draft, pending, approved, rejected }

class ServiceArea {
  const ServiceArea({
    required this.lat,
    required this.lng,
    required this.radiusKm,
  });

  final double lat;
  final double lng;
  final double radiusKm;
}

class MechanicProfile {
  const MechanicProfile({
    required this.id,
    required this.displayName,
    required this.photoPath,
    required this.yearsExperience,
    required this.languages,
    required this.serviceArea,
    required this.verified,
    required this.verificationStatus,
    required this.online,
    this.rejectionReason,
  });

  final String id;
  final String displayName;
  final String photoPath;
  final int yearsExperience;
  final List<String> languages;
  final ServiceArea? serviceArea;
  final bool verified;
  final VerificationStatus verificationStatus;
  final bool online;
  final String? rejectionReason;

  bool get canGoOnline =>
      verified && verificationStatus == VerificationStatus.approved;
}

class SignedUpload {
  const SignedUpload({
    required this.uploadUrl,
    required this.path,
  });

  final String uploadUrl;
  final String path;
}

class ApplicationInput {
  const ApplicationInput({
    required this.displayName,
    required this.photoPath,
    required this.yearsExperience,
    required this.languages,
    required this.serviceArea,
    required this.documents,
  });

  final String displayName;
  final String photoPath;
  final int yearsExperience;
  final List<String> languages;
  final ServiceArea serviceArea;
  final Map<MechanicDocumentKind, String> documents;
}

abstract interface class MechanicRepository {
  Future<Result<MechanicProfile>> getProfile(String idToken);

  Future<Result<MechanicProfile>> submitApplication(
    String idToken,
    ApplicationInput input,
  );

  Future<Result<MechanicProfile>> setAvailability(
    String idToken, {
    required bool online,
  });

  Future<Result<MechanicProfile>> heartbeat(String idToken);

  Future<Result<SignedUpload>> signUpload(
    String idToken, {
    required String path,
    required String contentType,
    required int maxBytes,
  });
}
