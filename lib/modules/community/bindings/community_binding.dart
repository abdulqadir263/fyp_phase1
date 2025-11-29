import 'package:get/get.dart';
import '../controllers/community_controller.dart';
import '../services/community_service.dart';

/// Binding for community module
class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    // Register CommunityService if not already registered
    if (!Get.isRegistered<CommunityService>()) {
      Get.lazyPut<CommunityService>(() => CommunityService());
    }
    
    // Register CommunityController
    Get.lazyPut<CommunityController>(() => CommunityController());
  }
}
