/// Route name constants for GoRouter
class RouteNames {
  RouteNames._();

  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String locationPermission = '/location-permission';
  static const String notificationPermission = '/notification-permission';

  // Main Shell
  static const String home = '/home';
  static const String notifications = '/notifications';

  // Bikes
  static const String myBikes = '/bikes';
  static const String addBike = '/bikes/add';
  static const String editBike = '/bikes/edit';
  static const String bikeDetails = '/bikes/details';

  // Booking
  static const String booking = '/booking';
  static const String bookingSuccess = '/booking/success';
  static const String bookingDetails = '/booking/details';
  static const String reschedule = '/booking/reschedule';

  // Tracking
  static const String liveTracking = '/tracking';
  static const String serviceProgress = '/tracking/progress';

  // Inspection & Invoice
  static const String inspection = '/inspection';
  static const String photoGallery = '/inspection/gallery';
  static const String invoice = '/invoice';

  // Wallet
  static const String wallet = '/wallet';
  static const String addMoney = '/wallet/add';

  // Offers
  static const String offers = '/offers';
  static const String offerDetails = '/offers/details';

  // Membership
  static const String membership = '/membership';
  static const String purchaseSuccess = '/membership/success';

  // Referral
  static const String referEarn = '/refer';

  // Emergency
  static const String emergency = '/emergency';
  static const String emergencyTracking = '/emergency/tracking';

  // Documents
  static const String documents = '/documents';
  static const String documentViewer = '/documents/view';

  // Support
  static const String support = '/support';
  static const String chat = '/support/chat';
  static const String ticket = '/support/ticket';
  static const String ticketHistory = '/support/tickets';

  // Profile
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String addresses = '/profile/addresses';
  static const String settings = '/profile/settings';

  // Fuel
  static const String fuelTracker = '/fuel';
  static const String addFuelLog = '/fuel/add';

  // Health
  static const String healthScore = '/health';

  // History
  static const String history = '/history';
  static const String serviceDetail = '/history/detail';
}
