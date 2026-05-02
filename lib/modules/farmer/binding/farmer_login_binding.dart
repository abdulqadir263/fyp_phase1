import 'package:get/get.dart';
import '../controllers/farmer_auth_controller.dart';

/// Binding for the FARMER_AUTH route (the new auth screen).
/// FarmerSessionController is put separately by FarmerAuthBinding on FARMER_SIGNUP.
class FarmerLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FarmerAuthController>(() => FarmerAuthController());
  }
}
