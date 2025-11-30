import 'package:get/get.dart';
import '../../modules/auth/controllers/auth_controller.dart';

// Auth module ke liye dependencies ko initialize karna
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthProvider is initialized in main.dart as permanent
    // Only initialize the AuthController here
    Get.lazyPut(() => AuthController());
  }
}
