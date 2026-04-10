import 'package:get/get.dart';
import '../view_model/appointment_controller.dart';
import '../view_model/expert_dashboard_controller.dart';
import '../repository/appointment_repository.dart';

/// Binding for the Field Visit / Appointments module
/// Registers service and controllers with GetX dependency injection
class AppointmentBinding extends Bindings {
  @override
  void dependencies() {
    // Service is initialized as permanent in main.dart,
    // but ensure it's registered if accessed directly via route
    if (!Get.isRegistered<AppointmentRepository>()) {
      Get.lazyPut<AppointmentRepository>(
        () => AppointmentRepository(),
        fenix: true,
      );
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
