import 'package:get/get.dart';
import '../../modules/auth/view/forgot_password_view.dart';
import '../../modules/auth/view/login_view.dart';
import '../../modules/auth/view/welcome_view.dart';
import '../../modules/auth/view/role_selection_view.dart';
import '../../modules/auth/view/profile_completion_view.dart';
import '../../modules/crop_tracker/binding/crop_tracker_binding.dart';
import '../../modules/crop_tracker/view/crop_tracker_view.dart';
import '../../modules/disease_detection/binding/disease_detection_binding.dart';
import '../../modules/disease_detection/view/disease_detection_screen.dart';
import '../../modules/home/view/home_view.dart';
import '../../modules/profile/view/profile_view.dart';
import '../../modules/weather/view/weather_view.dart';
import '../../modules/chatbot/view/chatbot_view.dart';
import '../../modules/community/view/community_view.dart';
import '../../modules/community/view/create_post_view.dart';
import '../../modules/community/view/post_detail_view.dart';
import '../../modules/community/view/bookmarks_view.dart';
// ========== FIELD VISIT MODULE IMPORTS ==========
import '../../modules/appointments/view/appointments_view.dart';
import '../../modules/appointments/view/expert_profile_view.dart';
import '../../modules/appointments/view/request_visit_view.dart';
import '../../modules/appointments/view/farmer_visits_view.dart';
import '../../modules/appointments/view/appointment_detail_view.dart';
import '../../modules/appointments/view/expert_dashboard_view.dart';
import '../../modules/appointments/binding/appointment_binding.dart';
// ========== MARKETPLACE MODULE IMPORTS ==========
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
// ========== CROP RECOMMENDATION MODULE IMPORTS ==========
import '../../modules/crop_recommendation/view/crop_input_screen.dart';
import '../../modules/crop_recommendation/view/crop_result_screen.dart';
import '../../modules/crop_recommendation/view/recommendation_history_screen.dart';
import '../../modules/crop_recommendation/binding/crop_recommendation_binding.dart';
import '../middleware/role_middleware.dart';
import '../../modules/auth/binding/auth_binding.dart';
import '../../modules/auth/binding/onboarding_binding.dart';
import '../../modules/home/binding/home_binding.dart';
import '../../modules/profile/binding/profile_binding.dart';
import '../../modules/weather/binding/weather_binding.dart';
import '../../modules/chatbot/binding/chatbot_binding.dart';
import '../../modules/community/binding/community_binding.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    // Auth Pages
    GetPage(name: AppRoutes.WELCOME, page: () => const WelcomeView()),
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
    GetPage(
      name: AppRoutes.DISEASE_DETECTION,
      page: () => const DiseaseDetectionScreen(),
      binding: DiseaseDetectionBinding(),
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
