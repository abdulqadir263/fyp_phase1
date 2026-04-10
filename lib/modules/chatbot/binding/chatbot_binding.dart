import 'package:get/get.dart';
import '../view_model/chatbot_controller.dart';
import '../repository/chat_repository.dart';

/// Binding for chatbot module
class ChatbotBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ChatRepository>()) {
      Get.lazyPut<ChatRepository>(() => ChatRepository(), fenix: true);
    }
    Get.lazyPut<ChatbotController>(() => ChatbotController());
  }
}
