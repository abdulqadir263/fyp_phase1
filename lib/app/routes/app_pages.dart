import 'package:get/get.dart';
import '../../modules/auth/views/forgot_password_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/profile/views/profile_view.dart';
import '../../modules/weather/views/weather_view.dart';
import '../../modules/chatbot/views/chatbot_view.dart';
import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/weather_binding.dart';
import '../bindings/chatbot_binding.dart';
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
  ];
}