import 'package:get/get.dart';
import '../../modules/home/controllers/home_controller.dart';

// Home module ke liye dependencies ko initialize karna
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // HomeController ko lazy load karein
    Get.lazyPut(() => HomeController());
  }
}