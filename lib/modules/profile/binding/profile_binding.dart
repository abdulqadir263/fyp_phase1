import 'package:get/get.dart';
import '../view_model/profile_controller.dart';
import '../repository/profile_repository.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut(() => ProfileRepository(), fenix: true);
    }
    Get.lazyPut(() => ProfileController(), fenix: true); // Get.put ki jagah lazyPut + fenix:true
  }
}
