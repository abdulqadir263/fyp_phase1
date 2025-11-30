import 'package:get/get.dart';
import '../controllers/community_controller.dart';

/// Binding for community module
class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    // CommunityService is initialized in main.dart as permanent
    // Register CommunityController - use put to ensure it's always available
    if (!Get.isRegistered<CommunityController>()) {
      Get.put<CommunityController>(CommunityController());
    }
  }
}
