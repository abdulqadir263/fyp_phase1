import 'package:get/get.dart';
import '../../modules/splash/splash_screen.dart';
import '../../modules/splash/splash_binding.dart';
import '../../modules/auth/view/welcome_view.dart';
import '../../modules/auth/view/role_selection_view.dart';

// ========== NEW ROLE AUTH IMPORTS ==========
import '../../modules/farmer/view/farmer_auth_view.dart';
import '../../modules/farmer/view/farmer_signup_view.dart';
import '../../modules/farmer/binding/farmer_auth_binding.dart';
import '../../modules/farmer/binding/farmer_login_binding.dart';

import '../../modules/expert/view/expert_auth_view.dart';
import '../../modules/expert/view/expert_profile_setup_view.dart';
import '../../modules/expert/binding/expert_auth_binding.dart';

import '../../modules/seller/view/seller_auth_view.dart';
import '../../modules/seller/view/seller_profile_setup_view.dart';
import '../../modules/seller/binding/seller_auth_binding.dart';

import '../../modules/shared/view/email_verification_pending_view.dart';

// ========== FEATURE IMPORTS ==========
import '../../modules/crop_tracker/binding/crop_tracker_binding.dart';
import '../../modules/crop_tracker/view/crop_tracker_view.dart';
import '../../modules/disease_detection/binding/disease_detection_binding.dart';
import '../../modules/disease_detection/view/disease_detection_screen.dart';
import '../../modules/disease_detection/view/disease_history_screen.dart';
import '../../modules/home/view/home_view.dart';
import '../../modules/profile/view/profile_view.dart';
import '../../modules/weather/view/weather_view.dart';
import '../../modules/chatbot/view/chatbot_view.dart';
import '../../modules/community/view/community_view.dart';
import '../../modules/community/view/create_post_view.dart';
import '../../modules/community/view/post_detail_view.dart';
import '../../modules/community/view/bookmarks_view.dart';
import '../../modules/appointments/view/appointments_view.dart';
import '../../modules/appointments/view/expert_profile_view.dart';
import '../../modules/appointments/view/request_visit_view.dart';
import '../../modules/appointments/view/farmer_visits_view.dart';
import '../../modules/appointments/view/appointment_detail_view.dart';
import '../../modules/appointments/view/expert_dashboard_view.dart';
import '../../modules/appointments/view/expert_detail_view.dart';
import '../../modules/appointments/view/appointment_confirmation_view.dart';
import '../../modules/appointments/view/expert_appointments_view.dart';
import '../../modules/appointments/view/farmer_appointments_view.dart';
import '../../modules/appointments/binding/appointment_binding.dart';
import '../../modules/marketplace/view/marketplace_view.dart';
import '../../modules/marketplace/view/product_detail_view.dart';
import '../../modules/marketplace/view/cart_view.dart';
import '../../modules/marketplace/view/checkout_view.dart';
import '../../modules/marketplace/view/my_products_view.dart';
import '../../modules/marketplace/view/add_product_view.dart';
import '../../modules/marketplace/view/seller_orders_view.dart';
import '../../modules/marketplace/view/seller_dashboard_view.dart';
import '../../modules/marketplace/view/order_history_view.dart';
import '../../modules/marketplace/view/order_detail_view.dart';
import '../../modules/marketplace/binding/marketplace_binding.dart';
import '../../modules/crop_recommendation/view/crop_input_screen.dart';
import '../../modules/crop_recommendation/view/crop_result_screen.dart';
import '../../modules/crop_recommendation/view/recommendation_history_screen.dart';
import '../../modules/crop_recommendation/binding/crop_recommendation_binding.dart';

import '../middleware/role_middleware.dart';
import '../../modules/home/binding/home_binding.dart';
import '../../modules/profile/binding/profile_binding.dart';
import '../../modules/weather/binding/weather_binding.dart';
import '../../modules/chatbot/binding/chatbot_binding.dart';
import '../../modules/community/binding/community_binding.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    // ── Splash (initial route) ──────────────────────────────────────────────
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fade,
      transitionDuration: Duration.zero,
    ),

    // ── Auth Pages ──────────────────────────────────────────────────────────
    GetPage(name: AppRoutes.WELCOME, page: () => const WelcomeView()),
    GetPage(name: AppRoutes.ROLE_SELECTION, page: () => const RoleSelectionView()),
    
    // Farmer Auth
    GetPage(
      name: AppRoutes.FARMER_AUTH,
      page: () => const FarmerAuthView(),
      binding: FarmerLoginBinding(),
    ),
    GetPage(
      name: AppRoutes.FARMER_SIGNUP,
      page: () => const FarmerSignupView(),
      binding: FarmerAuthBinding(),
    ),
    
    // Expert Auth
    GetPage(
      name: AppRoutes.EXPERT_AUTH,
      page: () => const ExpertAuthView(),
      binding: ExpertAuthBinding(),
    ),
    GetPage(
      name: AppRoutes.EXPERT_PROFILE_SETUP,
      page: () => const ExpertProfileSetupView(),
      binding: ExpertAuthBinding(),
    ),
    
    // Seller Auth
    GetPage(
      name: AppRoutes.SELLER_AUTH,
      page: () => const SellerAuthView(),
      binding: SellerAuthBinding(),
    ),
    GetPage(
      name: AppRoutes.SELLER_PROFILE_SETUP,
      page: () => const SellerProfileSetupView(),
      binding: SellerAuthBinding(),
    ),
    
    // Shared verification pending
    GetPage(
      name: AppRoutes.EMAIL_VERIFICATION_PENDING,
      page: () => const EmailVerificationPendingView(),
      binding: SellerAuthBinding()
    ),

    // ── Feature Pages ───────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.DISEASE_DETECTION,
      page: () => const DiseaseDetectionScreen(),
      binding: DiseaseDetectionBinding(),
    ),
    GetPage(
      name: AppRoutes.DISEASE_DETECTION_HISTORY,
      page: () => const DiseaseHistoryScreen(),
      binding: DiseaseDetectionBinding(),
    ),

    // Main Pages
    GetPage(
      name: AppRoutes.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => ProfileView(),
      binding: ProfileBinding(),
    ),

    // Weather
    GetPage(
      name: AppRoutes.WEATHER,
      page: () => WeatherView(),
      binding: WeatherBinding(),
      middlewares: [RoleMiddleware()],
    ),

    GetPage(
      name: AppRoutes.CROP_TRACKER,
      page: () => const CropTrackerView(),
      binding: CropTrackerBinding(),
    ),
    // Chatbot
    GetPage(
      name: AppRoutes.CHATBOT,
      page: () => const ChatbotView(),
      binding: ChatbotBinding(),
      middlewares: [RoleMiddleware()],
    ),

    // ========== FIELD VISIT / APPOINTMENTS MODULE ==========
    GetPage(
      name: AppRoutes.APPOINTMENTS,
      page: () => const ExpertListView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.EXPERT_PROFILE,
      page: () => const ExpertProfileView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.REQUEST_VISIT,
      page: () => const RequestVisitView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.MY_VISITS,
      page: () => const FarmerVisitsView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.VISIT_DETAIL,
      page: () => const AppointmentDetailView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.EXPERT_DASHBOARD,
      page: () => const ExpertDashboardView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.EXPERT_DETAIL,
      page: () => const ExpertDetailView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.APPOINTMENT_CONFIRMATION,
      page: () => const AppointmentConfirmationView(),
    ),
    GetPage(
      name: AppRoutes.EXPERT_APPOINTMENTS,
      page: () => const ExpertAppointmentsView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.FARMER_APPOINTMENTS,
      page: () => const FarmerAppointmentsView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),

    // ========== MARKETPLACE MODULE ==========
    GetPage(
      name: AppRoutes.MARKETPLACE,
      page: () => const MarketplaceHomeView(),
      binding: MarketplaceBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.MARKETPLACE_PRODUCT,
      page: () => const ProductDetailView(),
      binding: MarketplaceBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.MARKETPLACE_CART,
      page: () => const CartView(),
      binding: MarketplaceBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.MARKETPLACE_CHECKOUT,
      page: () => const CheckoutView(),
      binding: MarketplaceBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.SELLER_PRODUCTS,
      page: () => const SellerProductsView(),
      binding: MarketplaceBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.SELLER_ADD_PRODUCT,
      page: () => const AddProductView(),
      binding: MarketplaceBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.SELLER_ORDERS,
      page: () => const SellerOrdersView(),
      binding: MarketplaceBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.SELLER_DASHBOARD,
      page: () => const SellerDashboardView(),
      binding: MarketplaceBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ORDER_HISTORY,
      page: () => const OrderHistoryView(),
      binding: MarketplaceBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ORDER_DETAIL,
      page: () => const OrderDetailView(),
      binding: MarketplaceBinding(),
      middlewares: [RoleMiddleware()],
    ),

    // ========== CROP RECOMMENDATION MODULE ==========
    GetPage(
      name: AppRoutes.CROP_RECOMMENDATION,
      page: () => const CropInputScreen(),
      binding: CropRecommendationBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.CROP_RECOMMENDATION_RESULTS,
      page: () => const CropResultScreen(),
      binding: CropRecommendationBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.CROP_RECOMMENDATION_HISTORY,
      page: () => const RecommendationHistoryScreen(),
      binding: CropRecommendationBinding(),
      middlewares: [RoleMiddleware()],
    ),

    // Community
    GetPage(
      name: AppRoutes.COMMUNITY,
      page: () => const CommunityView(),
      binding: CommunityBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: '/community/create',
      page: () => const CreatePostView(),
      binding: CommunityBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: '/community/post/:id',
      page: () => const PostDetailView(),
      binding: CommunityBinding(),
      middlewares: [RoleMiddleware()],
    ),
    GetPage(
      name: '/community/bookmarks',
      page: () => const BookmarksView(),
      binding: CommunityBinding(),
      middlewares: [RoleMiddleware()],
    ),
  ];
}
