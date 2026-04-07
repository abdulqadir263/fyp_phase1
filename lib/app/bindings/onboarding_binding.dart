import 'package:get/get.dart';
import '../../modules/auth/controllers/onboarding_controller.dart';

/// OnboardingBinding - Dependency injection for onboarding flow
/// Provides OnboardingController for RoleSelectionView and ProfileCompletionView
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OnboardingController>()) {
      Get.lazyPut(() => OnboardingController(), fenix: true);
    }
  }
}
