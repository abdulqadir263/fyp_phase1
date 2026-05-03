import 'package:get/get.dart';
import '../controllers/expert_auth_controller.dart';

class ExpertAuthBinding extends Bindings {
  @override
  void dependencies() {
    // ExpertAuthBinding (wherever you register this controller)
    Get.lazyPut<ExpertAuthController>(() => ExpertAuthController(), fenix: true); // FIX 1
  }
}
