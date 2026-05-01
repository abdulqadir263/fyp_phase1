import 'package:get/get.dart';
import '../view_model/appointment_controller.dart';
import '../view_model/booking_controller.dart';
import '../view_model/expert_appointment_controller.dart';
import '../view_model/farmer_appointments_controller.dart';
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

    // Farmer booking controller (slot-based)
    if (!Get.isRegistered<BookingController>()) {
      Get.lazyPut<BookingController>(
        () => BookingController(),
        fenix: true,
      );
    }

    // Expert consultation appointments controller (real-time)
    if (!Get.isRegistered<ExpertAppointmentController>()) {
      Get.lazyPut<ExpertAppointmentController>(
        () => ExpertAppointmentController(),
        fenix: true,
      );
    }

    // Farmer's own appointments list controller (real-time, standalone)
    if (!Get.isRegistered<FarmerAppointmentsController>()) {
      Get.lazyPut<FarmerAppointmentsController>(
        () => FarmerAppointmentsController(),
        fenix: true,
      );
    }
  }
}
