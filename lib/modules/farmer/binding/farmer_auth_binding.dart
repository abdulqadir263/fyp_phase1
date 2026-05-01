import 'package:get/get.dart';
import '../farmer_session_controller.dart';

class FarmerAuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FarmerSessionController>(() => FarmerSessionController());
  }
}
