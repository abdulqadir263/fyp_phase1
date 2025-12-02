import 'package:get/get.dart';
import '../../modules/auth/controllers/auth_controller.dart';

// Auth module ke liye dependencies ko initialize karna
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthProvider is initialized in main.dart as permanent
    // Delete any existing AuthController to ensure clean state during navigation
    // This prevents TextEditingController disposal errors when navigating between auth screens
    if (Get.isRegistered<AuthController>()) {
      Get.delete<AuthController>(force: true);
    }
    // Use Get.put to ensure immediate controller creation with fresh TextEditingControllers
    Get.put(AuthController());
  }
}
