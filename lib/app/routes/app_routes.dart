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

  // Feature Routes — Field Visit / Appointments
  static const APPOINTMENTS = '/appointments';
  static const EXPERT_PROFILE = '/appointments/expert-profile';
  static const REQUEST_VISIT = '/appointments/request-visit';
  static const MY_VISITS = '/appointments/my-visits';
  static const VISIT_DETAIL = '/appointments/visit-detail';
  static const EXPERT_DASHBOARD = '/appointments/expert-dashboard';

  // Feature Routes — Marketplace
  static const MARKETPLACE = '/marketplace';
  static const MARKETPLACE_PRODUCT = '/marketplace/product';
  static const MARKETPLACE_CART = '/marketplace/cart';
  static const MARKETPLACE_CHECKOUT = '/marketplace/checkout';
  static const SELLER_PRODUCTS = '/marketplace/seller/products';
  static const SELLER_ADD_PRODUCT = '/marketplace/seller/add-product';
  static const SELLER_ORDERS = '/marketplace/seller/orders';
  static const SELLER_DASHBOARD = '/marketplace/seller/dashboard';
  static const ORDER_HISTORY = '/marketplace/orders';
  static const ORDER_DETAIL = '/marketplace/orders/detail';

  static const CROP_TRACKER = '/crop-tracker';
  static const COMMUNITY = '/community';
  static const CHATBOT = '/chatbot';

  // Additional Routes
  static const SETTINGS = '/settings';
  static const ABOUT = '/about';
}