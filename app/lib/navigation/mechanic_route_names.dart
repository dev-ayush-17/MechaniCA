class MechanicRouteNames {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const otp = '/otp';
  static const home = '/home';
  static const offer = '/mechanic/offers/:offerId';

  static String offerPath(String offerId) => '/mechanic/offers/$offerId';
}
