class AppRoutes {
  // Splash (initial route — checks session & role)
  static const SPLASH = '/';

  // Role Selection & Auth
  static const WELCOME = '/welcome';
  static const ROLE_SELECTION = '/role-selection';
  
  // Farmer Auth
  static const FARMER_AUTH = '/farmer/auth';
  static const FARMER_SIGNUP = '/farmer/signup';
  static const FARMER_OTP = '/farmer/otp';
  
  // Expert Auth
  static const EXPERT_AUTH = '/expert-auth';
  static const EXPERT_PROFILE_SETUP = '/expert-profile-setup';
  
  // Seller Auth
  static const SELLER_AUTH = '/seller-auth';
  static const SELLER_PROFILE_SETUP = '/seller-profile-setup';
  
  // Shared Auth
  static const EMAIL_VERIFICATION_PENDING = '/email-verification';

  // Main Routes
  static const HOME = '/home';
  static const PROFILE = '/profile';

  // Weather Routes
  static const WEATHER = '/weather';
  static const WEATHER_DETAIL = '/weather-detail';

  // Field Visit / Appointments Routes
  static const APPOINTMENTS = '/appointments';
  static const EXPERT_PROFILE = '/appointments/expert-profile';
  static const REQUEST_VISIT = '/appointments/request-visit';
  static const MY_VISITS = '/appointments/my-visits';
  static const VISIT_DETAIL = '/appointments/visit-detail';
  static const EXPERT_DASHBOARD = '/appointments/expert-dashboard';
  static const EXPERT_DETAIL = '/appointments/expert-detail';
  static const APPOINTMENT_CONFIRMATION = '/appointments/confirmation';
  static const EXPERT_APPOINTMENTS = '/appointments/expert-appointments';
  static const FARMER_APPOINTMENTS = '/appointments/my';

  // Marketplace Routes
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

  // Feature Routes
  static const CROP_TRACKER = '/crop-tracker';
  static const COMMUNITY = '/community';
  static const CHATBOT = '/chatbot';
  static const DISEASE_DETECTION = '/disease-detection';
  static const DISEASE_DETECTION_HISTORY = '/disease-detection/history';

  // Crop Recommendation Routes
  static const CROP_RECOMMENDATION = '/crop-recommendation';
  static const CROP_RECOMMENDATION_RESULTS = '/crop-recommendation/results';
  static const CROP_RECOMMENDATION_HISTORY = '/crop-recommendation/history';
}
