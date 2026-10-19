import '../../../core/error/result.dart';
import 'job_offer.dart';

abstract class OfferApi {
  Future<Result<JobOffer>> getOpen();

  Future<Result<JobOffer>> getById(String offerId);

  Future<Result<void>> accept(String offerId);

  Future<Result<void>> reject(String offerId);
}
