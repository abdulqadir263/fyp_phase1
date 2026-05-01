import 'package:get/get.dart';
import 'init_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(InitController());
  }
}
