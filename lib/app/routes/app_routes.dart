// Sare routes ki strings yahan par define karenge
class AppRoutes {
  // Auth Routes
  static const LOGIN = '/login';
  static const SIGNUP = '/signup';
  static const FORGOT_PASSWORD = '/forgot-password';

  // ========== NEW ONBOARDING ROUTES ==========
  /// Role selection screen after signup
  static const ROLE_SELECTION = '/role-selection';
  /// Profile completion screen based on selected role
  static const PROFILE_COMPLETION = '/profile-completion';

  // Main Routes
  static const HOME = '/home';
  static const PROFILE = '/profile';

  // Add these routes to your existing AppRoutes class
  static const WEATHER = '/weather';
  static const WEATHER_DETAIL = '/weather-detail';

  // Feature Routes
  static const APPOINTMENTS = '/appointments';
  static const MARKETPLACE = '/marketplace';
  static const CROP_TRACKER = '/crop-tracker';
  static const COMMUNITY = '/community';
  static const CHATBOT = '/chatbot';

  // Additional Routes
  static const SETTINGS = '/settings';
  static const ABOUT = '/about';
}