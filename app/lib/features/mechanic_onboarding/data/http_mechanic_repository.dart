import 'package:dio/dio.dart';

import '../../../core/api/generated/export.dart' as api;
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/mechanic_repository.dart';

class HttpMechanicRepository implements MechanicRepository {
  HttpMechanicRepository({required api.RestClient client}) : _client = client;

  final api.RestClient _client;

  @override
  Future<Result<MechanicProfile>> getProfile(String idToken) {
    return _call(idToken, (token) async {
      final out = await _client.mechanic.getMechanicProfileV1MechanicGet(
        authorization: 'Bearer $token',
      );
      return _toProfile(out);
    });
  }

  @override
  Future<Result<MechanicProfile>> submitApplication(
    String idToken,
    ApplicationInput input,
  ) {
    return _call(idToken, (token) async {
      final out = await _client.mechanic.submitApplicationV1MechanicApplicationPost(
        body: api.ApplicationRequest(
          displayName: input.displayName,
          photoPath: input.photoPath,
          yearsExperience: input.yearsExperience,
          languages: input.languages,
          serviceArea: api.ServiceAreaIn(
            lat: input.serviceArea.lat,
            lng: input.serviceArea.lng,
            radiusKm: input.serviceArea.radiusKm,
          ),
          documents: input.documents.entries
              .map(
                (e) => api.DocumentIn(
                  kind: _docKind(e.key),
                  storagePath: e.value,
                ),
              )
              .toList(),
        ),
        authorization: 'Bearer $token',
      );
      return _toProfile(out);
    });
  }

  @override
  Future<Result<MechanicProfile>> setAvailability(
    String idToken, {
    required bool online,
  }) {
    return _call(idToken, (token) async {
      final out = await _client.mechanic.setAvailabilityV1MechanicAvailabilityPost(
        body: api.AvailabilityRequest(online: online),
        authorization: 'Bearer $token',
      );
      return _toProfile(out);
    });
  }

  @override
  Future<Result<MechanicProfile>> heartbeat(String idToken) {
    return _call(idToken, (token) async {
      final out = await _client.mechanic.heartbeatV1MechanicHeartbeatPost(
        authorization: 'Bearer $token',
      );
      return _toProfile(out);
    });
  }

  @override
  Future<Result<SignedUpload>> signUpload(
    String idToken, {
    required String path,
    required String contentType,
    required int maxBytes,
  }) {
    return _callUpload(idToken, (token) async {
      final out = await _client.uploads.signUploadV1UploadsSignPost(
        body: api.SignUploadRequest(
          path: path,
          contentType: contentType,
          maxBytes: maxBytes,
        ),
        authorization: 'Bearer $token',
      );
      return SignedUpload(uploadUrl: out.uploadUrl, path: out.path);
    });
  }

  api.DocumentKind _docKind(MechanicDocumentKind kind) => switch (kind) {
        MechanicDocumentKind.licence => api.DocumentKind.licence,
        MechanicDocumentKind.governmentId => api.DocumentKind.governmentId,
        MechanicDocumentKind.selfie => api.DocumentKind.selfie,
      };

  MechanicProfile _toProfile(api.MechanicOut out) {
    final area = out.serviceArea;
    return MechanicProfile(
      id: out.id,
      displayName: out.displayName,
      photoPath: out.photoPath,
      yearsExperience: out.yearsExperience,
      languages: out.languages,
      serviceArea: area == null
          ? null
          : ServiceArea(
              lat: area.lat.toDouble(),
              lng: area.lng.toDouble(),
              radiusKm: area.radiusKm.toDouble(),
            ),
      verified: out.verified,
      verificationStatus: _status(out.verificationStatus),
      online: out.online,
      rejectionReason: out.rejectionReason,
    );
  }

  VerificationStatus _status(String value) => switch (value) {
        'pending' => VerificationStatus.pending,
        'approved' => VerificationStatus.approved,
        'rejected' => VerificationStatus.rejected,
        _ => VerificationStatus.draft,
      };

  Future<Result<MechanicProfile>> _call(
    String idToken,
    Future<MechanicProfile> Function(String token) request,
  ) async {
    try {
      return Ok(await request(idToken));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  Future<Result<SignedUpload>> _callUpload(
    String idToken,
    Future<SignedUpload> Function(String token) request,
  ) async {
    try {
      return Ok(await request(idToken));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }
}
