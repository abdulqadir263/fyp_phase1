import 'package:get/get.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../data/providers/auth_provider.dart';

// Auth module ke liye dependencies ko initialize karna
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Get.put() service ko register karta hai aur uska instance deta hai
    Get.lazyPut(() => AuthProvider());
    Get.lazyPut(() => AuthController());
  }
}

