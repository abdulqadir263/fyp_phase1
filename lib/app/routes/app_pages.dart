import 'package:get/get.dart';
import '../../modules/auth/views/forgot_password_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/profile/views/profile_view.dart';
import '../../modules/weather/views/weather_view.dart';
import '../../modules/chatbot/views/chatbot_view.dart';
import '../../modules/community/views/community_view.dart';
import '../../modules/community/views/create_post_view.dart';
import '../../modules/community/views/post_detail_view.dart';
import '../../modules/community/views/bookmarks_view.dart';
import '../bindings/auth_binding.dart';
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
      name: AppRoutes.LOGIN,
      page: () => LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.FORGOT_PASSWORD,
      page: () => ForgotPasswordView(),
      binding: AuthBinding(),
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
    ),

    // Chatbot
    GetPage(
      name: AppRoutes.CHATBOT,
      page: () => const ChatbotView(),
      binding: ChatbotBinding(),
    ),

    // Community
    GetPage(
      name: AppRoutes.COMMUNITY,
      page: () => const CommunityView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: '/community/create',
      page: () => const CreatePostView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: '/community/post/:id',
      page: () => const PostDetailView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: '/community/bookmarks',
      page: () => const BookmarksView(),
      binding: CommunityBinding(),
    ),
  ];
}