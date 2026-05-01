import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/themes/app_colors.dart';
import '../models/appointment_model.dart';
import '../view_model/expert_appointment_controller.dart';

/// ExpertAppointmentsView — real-time dashboard for experts to manage
/// consultation bookings.
///
/// Tabs:
///   Pending  — new bookings requiring action (Confirm / Cancel)
///   Confirmed — accepted bookings (Cancel / Mark Complete)
///   Past      — cancelled + completed history
class ExpertAppointmentsView
    extends GetView<ExpertAppointmentController> {
  const ExpertAppointmentsView({super.key});

  static const _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _blue),
            onPressed: Get.back,
          ),
          title: const Text(
            'My Appointments',
            style: TextStyle(
                color: _blue, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: _blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _blue,
            tabs: [
              Obx(() =>
                  Tab(text: 'Pending (${controller.pending.length})')),
              Obx(() =>
                  Tab(text: 'Confirmed (${controller.confirmed.length})')),
              const Tab(text: 'Past'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }
          return TabBarView(
            children: [
              _buildList(controller.pending, showPending: true),
              _buildList(controller.confirmed, showConfirmed: true),
              _buildList(controller.done, isPast: true),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildList(
    List<AppointmentModel> items, {
    bool showPending = false,
    bool showConfirmed = false,
    bool isPast = false,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPast ? Icons.history : Icons.event_busy,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              isPast
                  ? 'No past appointments.'
                  : 'No appointments here yet.',
              style: TextStyle(
                  fontSize: 15, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _AppointmentCard(
        appointment: items[i],
        onConfirm: showPending
            ? () => controller.confirmAppointment(items[i].id)
            : null,
        onCancel: (showPending || showConfirmed)
            ? () => _confirmCancel(items[i])
            : null,
        onComplete: showConfirmed
            ? () => controller.completeAppointment(items[i].id)
            : null,
      ),
    );
  }

  void _confirmCancel(AppointmentModel appt) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Cancel Appointment'),
        content: Text(
          'Cancel ${appt.farmerName}\'s appointment on '
          '${appt.day} at ${appt.slot}?',
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Keep It'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelAppointment(appt.id);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appointment Card ─────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;

  const _AppointmentCard({
    required this.appointment,
    this.onConfirm,
    this.onCancel,
    this.onComplete,
  });

  static const _blue = Color(0xFF1565C0);

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
          // Header row: farmer name + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  appointment.farmerName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
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

          // Day + slot + mode + fee + booked timestamp
          _infoRow(Icons.calendar_today, appointment.day, size: 15),
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
            'Booked: ${DateFormat('dd MMM yyyy, hh:mm a').format(appointment.bookedAt)}',
          ),

          // Action buttons
          if (onConfirm != null || onCancel != null || onComplete != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (onConfirm != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check,
                          size: 16, color: Colors.white),
                      label: const Text('Confirm',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                if (onConfirm != null && onCancel != null)
                  const SizedBox(width: 8),
                if (onComplete != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.done_all,
                          size: 16, color: Colors.white),
                      label: const Text('Complete',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                if (onComplete != null && onCancel != null)
                  const SizedBox(width: 8),
                if (onCancel != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.red),
                      label: const Text('Cancel',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {double size = 14}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: size, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
