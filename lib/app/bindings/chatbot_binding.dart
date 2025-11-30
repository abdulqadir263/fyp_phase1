import 'package:get/get.dart';
import '../../modules/chatbot/controllers/chatbot_controller.dart';

/// Binding for chatbot module
class ChatbotBinding extends Bindings {
  @override
  void dependencies() {
    // AuthProvider is initialized in main.dart as permanent
    // Initialize ChatbotController
    Get.lazyPut<ChatbotController>(() => ChatbotController());
  }
}
