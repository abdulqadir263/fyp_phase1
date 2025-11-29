import 'package:get/get.dart';
import '../../modules/chatbot/controllers/chatbot_controller.dart';
import '../data/providers/auth_provider.dart';

/// Binding for chatbot module
class ChatbotBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure AuthProvider is available
    if (!Get.isRegistered<AuthProvider>()) {
      Get.lazyPut<AuthProvider>(() => AuthProvider());
    }

    // Initialize ChatbotController
    Get.lazyPut<ChatbotController>(() => ChatbotController());
  }
}
