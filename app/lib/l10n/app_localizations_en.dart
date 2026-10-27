// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MechUpp';

  @override
  String get appTagline => 'Your Bike. Our Responsibility.';

  @override
  String get back => 'Back';

  @override
  String get pay => 'Pay (demo)';

  @override
  String get payNow => 'Pay now';

  @override
  String payAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String confirmBooking(String amount) {
    return 'Confirm $amount';
  }

  @override
  String get bookingReviewStep => 'Review';

  @override
  String get payAfterVisitHint => 'How you\'ll pay after the visit';

  @override
  String get noChargeUntilComplete =>
      'You are not charged until the mechanic completes the job.';

  @override
  String get payAfterTheVisit => 'Pay after the visit';

  @override
  String get trackLive => 'Track Live';

  @override
  String get liveTracking => 'Live Tracking';

  @override
  String get shareTracking => 'Share tracking';

  @override
  String get waitingForConfirmation => 'Waiting for confirmation';

  @override
  String get paid => 'Paid';

  @override
  String get paymentProcessing =>
      'Payment is still processing. We\'ll notify you.';

  @override
  String get labor => 'Labor';

  @override
  String get convenienceFee => 'Convenience fee';

  @override
  String get gst => 'GST';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get priceEstimate => 'Price Estimate';

  @override
  String get connectToBook => 'Connect to book.';

  @override
  String get sos => 'SOS';

  @override
  String get sosHoldHint => 'Hold for 2s';

  @override
  String get sosSemanticsHint => 'Hold for 2 seconds to request emergency help';

  @override
  String get emergencyAssistance => 'Emergency Assistance';

  @override
  String get needImmediateHelp => 'Need Immediate Help?';

  @override
  String get callSupport => 'Call Support';

  @override
  String get iAm18OrOlder => 'I am 18 or older';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';
}
