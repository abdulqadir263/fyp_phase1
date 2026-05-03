import 'package:get/get.dart';
import '../controllers/seller_auth_controller.dart';

class SellerAuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerAuthController>(() => SellerAuthController(),fenix: true);
    // Get.put(() => SellerAuthController(),);
  }
}
