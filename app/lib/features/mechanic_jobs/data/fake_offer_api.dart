import '../../../core/error/result.dart';
import '../domain/job_offer.dart';
import '../domain/offer_api.dart';

class FakeOfferApi implements OfferApi {
  FakeOfferApi({JobOffer? seed}) : offer = seed;

  JobOffer? offer;
  bool acceptCalled = false;
  bool rejectCalled = false;

  @override
  Future<Result<JobOffer>> getOpen() async {
    final current = offer;
    if (current == null) return const Err(NotFound('No open offer.'));
    return Ok(current);
  }

  @override
  Future<Result<JobOffer>> getById(String offerId) async {
    final current = offer;
    if (current == null || current.id != offerId) {
      return const Err(NotFound('We could not find that offer.'));
    }
    return Ok(current);
  }

  @override
  Future<Result<void>> accept(String offerId) async {
    acceptCalled = true;
    return const Ok(null);
  }

  @override
  Future<Result<void>> reject(String offerId) async {
    rejectCalled = true;
    offer = null;
    return const Ok(null);
  }
}
