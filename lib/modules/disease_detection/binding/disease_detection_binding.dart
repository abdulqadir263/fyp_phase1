import 'package:get/get.dart';
import '../view_model/disease_detection_controller.dart';

/// Binding for the Disease Detection module.
class DiseaseDetectionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DiseaseDetectionController>()) {
      Get.lazyPut<DiseaseDetectionController>(
        () => DiseaseDetectionController(),
        fenix: true,
      );
    }
  }
}