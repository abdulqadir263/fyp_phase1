import 'package:get/get.dart';
import '../../modules/profile/controllers/profile_controller.dart';

// Profile module ke liye dependencies ko initialize karna
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // ProfileController ko lazy load karein
    Get.lazyPut(() => ProfileController());
  }
}