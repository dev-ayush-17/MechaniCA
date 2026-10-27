// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'MechUpp';

  @override
  String get appTagline => 'आपकी बाइक। हमारी ज़िम्मेदारी।';

  @override
  String get back => 'वापस';

  @override
  String get pay => 'Pay (demo)';

  @override
  String get payNow => 'अभी भुगतान करें';

  @override
  String payAmount(String amount) {
    return '$amount का भुगतान करें';
  }

  @override
  String confirmBooking(String amount) {
    return '$amount की पुष्टि करें';
  }

  @override
  String get bookingReviewStep => 'समीक्षा';

  @override
  String get payAfterVisitHint => 'विज़िट के बाद आप कैसे भुगतान करेंगे';

  @override
  String get noChargeUntilComplete =>
      'मैकेनिक काम पूरा करने तक आपसे शुल्क नहीं लिया जाएगा।';

  @override
  String get payAfterTheVisit => 'विज़िट के बाद भुगतान';

  @override
  String get trackLive => 'लाइव ट्रैक करें';

  @override
  String get liveTracking => 'लाइव ट्रैकिंग';

  @override
  String get shareTracking => 'ट्रैकिंग शेयर करें';

  @override
  String get waitingForConfirmation => 'पुष्टि का इंतज़ार';

  @override
  String get paid => 'भुगतान हो गया';

  @override
  String get paymentProcessing =>
      'भुगतान अभी प्रोसेस हो रहा है। हम आपको सूचित करेंगे।';

  @override
  String get labor => 'लेबर';

  @override
  String get convenienceFee => 'सुविधा शुल्क';

  @override
  String get gst => 'GST';

  @override
  String get totalAmount => 'कुल राशि';

  @override
  String get priceEstimate => 'कीमत का अनुमान';

  @override
  String get connectToBook => 'बुक करने के लिए कनेक्ट करें।';

  @override
  String get sos => 'SOS';

  @override
  String get sosHoldHint => '2 सेकंड दबाकर रखें';

  @override
  String get sosSemanticsHint => 'आपातकालीन मदद के लिए 2 सेकंड दबाकर रखें';

  @override
  String get emergencyAssistance => 'आपातकालीन सहायता';

  @override
  String get needImmediateHelp => 'तुरंत मदद चाहिए?';

  @override
  String get callSupport => 'सपोर्ट को कॉल करें';

  @override
  String get iAm18OrOlder => 'मैं 18 वर्ष या उससे अधिक हूँ';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get next => 'आगे';
}
