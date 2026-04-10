import 'package:get/get.dart';
import '../view_model/crop_recommendation_controller.dart';

/// Binding for the Crop Recommendation module.
class CropRecommendationBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CropRecommendationController>()) {
      Get.lazyPut<CropRecommendationController>(
        () => CropRecommendationController(),
        fenix: true,
      );
    }
  }
}
