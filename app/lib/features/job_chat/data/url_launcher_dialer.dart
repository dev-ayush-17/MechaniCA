import 'package:url_launcher/url_launcher.dart';

/// Opens the platform dialer for a masked number.
abstract interface class Dialer {
  Future<void> open(String dialNumber);
}

class UrlLauncherDialer implements Dialer {
  @override
  Future<void> open(String dialNumber) {
    return launchUrl(Uri(scheme: 'tel', path: dialNumber));
  }
}
