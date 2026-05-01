import 'package:get/get.dart';
import '../controllers/expert_auth_controller.dart';

class ExpertAuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExpertAuthController>(() => ExpertAuthController());
  }
}
