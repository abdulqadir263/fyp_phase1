import 'package:get/get.dart';
import '../view_model/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut(() => AuthController(), fenix: true);
    }
  }
}
