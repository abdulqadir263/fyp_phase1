import 'package:get/get.dart';
import '../view_model/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    // isRegistered check hata do — permanent: true khud handle karta hai
    Get.put(OnboardingController(), permanent: true);
  }
}