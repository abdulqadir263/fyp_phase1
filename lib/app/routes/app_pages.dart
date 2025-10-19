import 'package:get/get.dart';
import '../../modules/auth/views/forgot_password_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/auth/views/signup_view.dart';
import '../../modules/home/views/home_view.dart';
import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import 'app_routes.dart';

// Routes ko unke respective views se map karta hai
class AppPages {
  static final routes = [
    // Auth Pages
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.SIGNUP,
      page: () => SignupView(),
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
    // GetPage(
    //   name: AppRoutes.PROFILE,
    //   page: () => ProfileView(),
    //   binding: ProfileBinding(),
    // ),

    // Baad mein baki routes add karenge jaise app barte jayenge
  ];
}