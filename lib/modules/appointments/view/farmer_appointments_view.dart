import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_colors.dart';
import '../models/appointment_model.dart';
import '../view_model/farmer_appointments_controller.dart';

/// FarmerAppointmentsView — real-time list of a farmer's consultation
/// bookings. Status badge updates live via Firestore snapshot stream.
///
/// Controller: FarmerAppointmentsController (standalone, no expert argument).
class FarmerAppointmentsView
    extends GetView<FarmerAppointmentsController> {
  const FarmerAppointmentsView({super.key});

  static const _green = AppColors.primaryGreen;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _green),
            onPressed: Get.back,
          ),
          title: const Text(
            'My Appointments',
            style: TextStyle(
                color: _green, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: _green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _green,
            tabs: [
              Obx(() => Tab(text: 'Active (${controller.active.length})')),
              Obx(() => Tab(text: 'Past (${controller.past.length})')),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: _green),
            );
          }
          if (controller.hasError.value) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: controller.retry,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Retry',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return TabBarView(
            children: [
              _buildList(controller.active, showRebook: false),
              _buildList(controller.past, showRebook: true),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildList(
      List<AppointmentModel> items, {
        required bool showRebook,
      }) {
    if (items.isEmpty) {
      return _buildEmptyState(showRebook);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _FarmerAppointmentCard(
        appointment: items[i],
        showRebook: showRebook && items[i].status == 'cancelled',
      ),
    );
  }

  Widget _buildEmptyState(bool isPast) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPast ? Icons.history : Icons.event_available,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isPast ? 'No past appointments' : 'No appointments yet',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              isPast
                  ? 'Completed or cancelled appointments will appear here.'
                  : 'Browse experts and book a consultation slot.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            if (!isPast) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.APPOINTMENTS),
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text('Find an Expert',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Single appointment card ──────────────────────────────────────────────────

class _FarmerAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool showRebook;

  const _FarmerAppointmentCard({
    required this.appointment,
    required this.showRebook,
  });

  static const _green = AppColors.primaryGreen;

  Color get _statusColor {
    switch (appointment.status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: expert name + live status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  appointment.expertName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appointment.statusLabel,
                  style: TextStyle(
                      fontSize: 12,
                      color: _statusColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _infoRow(Icons.calendar_today, appointment.day),
          const SizedBox(height: 4),
          _infoRow(Icons.access_time, appointment.slot),
          const SizedBox(height: 4),
          _infoRow(Icons.devices_outlined, appointment.consultationMode),
          const SizedBox(height: 4),
          _infoRow(
            Icons.currency_rupee,
            appointment.fee == 0 ? 'Free' : 'PKR ${appointment.fee}',
          ),
          const SizedBox(height: 4),
          _infoRow(
            Icons.schedule,
            'Booked ${DateFormat('dd MMM yyyy, hh:mm a')
                .format(appointment.bookedAt)}',
          ),

          // Rebook button for cancelled appointments
          if (showRebook) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.APPOINTMENTS),
                icon: const Icon(Icons.refresh, color: _green, size: 16),
                label: const Text('Find Another Expert',
                    style: TextStyle(color: _green)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _green),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
