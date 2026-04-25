import 'package:get/get.dart';
import '../view_model/crop_tracker_view_model.dart';
import '../repositories/crop_repository.dart';

class CropTrackerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ICropRepository>(() => CropRepository());
    Get.lazyPut<CropTrackerViewModel>(
          () => CropTrackerViewModel(
        repo: Get.find<ICropRepository>(),
      ),
    );
  }
}