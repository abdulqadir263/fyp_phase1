import 'package:get/get.dart';
import '../controllers/appointment_controller.dart';
import '../controllers/expert_dashboard_controller.dart';
import '../services/appointment_service.dart';

/// Binding for the Field Visit / Appointments module
/// Registers service and controllers with GetX dependency injection
class AppointmentBinding extends Bindings {
  @override
  void dependencies() {
    // Service is initialized as permanent in main.dart,
    // but ensure it's registered if accessed directly via route
    if (!Get.isRegistered<AppointmentService>()) {
      Get.lazyPut<AppointmentService>(() => AppointmentService(), fenix: true);
    }

    // Farmer-side controller
    if (!Get.isRegistered<AppointmentController>()) {
      Get.lazyPut<AppointmentController>(
        () => AppointmentController(),
        fenix: true,
      );
    }

    // Expert-side controller
    if (!Get.isRegistered<ExpertDashboardController>()) {
      Get.lazyPut<ExpertDashboardController>(
        () => ExpertDashboardController(),
        fenix: true,
      );
    }
  }
}
