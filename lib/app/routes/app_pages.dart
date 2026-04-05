import 'package:get/get.dart';
import '../../modules/auth/views/forgot_password_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/auth/views/welcome_view.dart';
import '../../modules/auth/views/role_selection_view.dart';
import '../../modules/auth/views/profile_completion_view.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/profile/views/profile_view.dart';
import '../../modules/weather/views/weather_view.dart';
import '../../modules/chatbot/views/chatbot_view.dart';
import '../../modules/community/views/community_view.dart';
import '../../modules/community/views/create_post_view.dart';
import '../../modules/community/views/post_detail_view.dart';
import '../../modules/community/views/bookmarks_view.dart';
// ========== FIELD VISIT MODULE IMPORTS ==========
import '../../modules/appointments/views/appointments_view.dart';
import '../../modules/appointments/views/expert_profile_view.dart';
import '../../modules/appointments/views/request_visit_view.dart';
import '../../modules/appointments/views/farmer_visits_view.dart';
import '../../modules/appointments/views/appointment_detail_view.dart';
import '../../modules/appointments/views/expert_dashboard_view.dart';
import '../../modules/appointments/bindings/appointment_binding.dart';
// ========== MARKETPLACE MODULE IMPORTS ==========
import '../../modules/marketplace/views/marketplace_view.dart';
import '../../modules/marketplace/views/product_detail_view.dart';
import '../../modules/marketplace/views/cart_view.dart';
import '../../modules/marketplace/views/checkout_view.dart';
import '../../modules/marketplace/views/my_products_view.dart';
import '../../modules/marketplace/views/add_product_view.dart';
import '../../modules/marketplace/views/seller_orders_view.dart';
import '../../modules/marketplace/views/seller_dashboard_view.dart';
import '../../modules/marketplace/views/order_history_view.dart';
import '../../modules/marketplace/views/order_detail_view.dart';
import '../../modules/marketplace/bindings/marketplace_binding.dart';
// ========== CROP RECOMMENDATION MODULE IMPORTS ==========
import '../../modules/crop_recommendation/views/crop_input_screen.dart';
import '../../modules/crop_recommendation/views/crop_result_screen.dart';
import '../../modules/crop_recommendation/views/recommendation_history_screen.dart';
import '../../modules/crop_recommendation/bindings/crop_recommendation_binding.dart';
import '../middleware/role_middleware.dart';
import '../bindings/auth_binding.dart';
import '../bindings/onboarding_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/weather_binding.dart';
import '../bindings/chatbot_binding.dart';
import '../../modules/community/bindings/community_binding.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    // Auth Pages
    GetPage(
      name: AppRoutes.WELCOME,
      page: () => const WelcomeView(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.FORGOT_PASSWORD,
      page: () => ForgotPasswordView(),
      binding: AuthBinding(),
    ),

    // ========== NEW ONBOARDING PAGES ==========
    GetPage(
      name: AppRoutes.ROLE_SELECTION,
      page: () => const RoleSelectionView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.PROFILE_COMPLETION,
      page: () => const ProfileCompletionView(),
      binding: OnboardingBinding(),
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

    // Chatbot
    GetPage(
      name: AppRoutes.CHATBOT,
      page: () => const ChatbotView(),
      binding: ChatbotBinding(),
      middlewares: [RoleMiddleware()],
    ),

    // ========== FIELD VISIT / APPOINTMENTS MODULE ==========
    // Expert list screen (farmer browses experts)
    GetPage(
      name: AppRoutes.APPOINTMENTS,
      page: () => const ExpertListView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    // Expert profile detail (farmer views expert info)
    GetPage(
      name: AppRoutes.EXPERT_PROFILE,
      page: () => const ExpertProfileView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    // Request visit form (farmer fills form)
    GetPage(
      name: AppRoutes.REQUEST_VISIT,
      page: () => const RequestVisitView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    // Farmer's own visits list
    GetPage(
      name: AppRoutes.MY_VISITS,
      page: () => const FarmerVisitsView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    // Visit detail (full view)
    GetPage(
      name: AppRoutes.VISIT_DETAIL,
      page: () => const AppointmentDetailView(),
      binding: AppointmentBinding(),
      middlewares: [RoleMiddleware()],
    ),
    // Expert dashboard (expert manages visits)
    GetPage(
      name: AppRoutes.EXPERT_DASHBOARD,
      page: () => const ExpertDashboardView(),
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