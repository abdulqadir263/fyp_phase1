import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../controllers/appointment_controller.dart';
import '../models/field_visit_model.dart';

/// FarmerVisitsView — Shows farmer's own visit requests with status
/// Allows cancelling pending visits
class FarmerVisitsView extends GetView<AppointmentController> {
  const FarmerVisitsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Load farmer visits when view opens
    controller.loadFarmerVisits();

    return Scaffold(
      appBar: AppBar(title: Text('appointments'.tr), centerTitle: true),

      // FAB to request a new visit
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/appointments'),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Request', style: TextStyle(color: Colors.white)),
      ),

      body: ResponsiveHelper.tabletCenter(
        child: Obx(() {
          // Loading state
          if (controller.isLoadingVisits.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          // Empty state
          if (controller.farmerVisits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No visit requests yet.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Request an expert to visit your farm!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Visits list
          return RefreshIndicator(
            onRefresh: controller.loadFarmerVisits,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.farmerVisits.length,
              itemBuilder: (context, index) {
                final visit = controller.farmerVisits[index];
                return _VisitCard(
                  visit: visit,
                  onCancel: visit.status == 'pending'
                      ? () => _showCancelDialog(context, visit)
                      : null,
                );
              },
            ),
          );
        }),
      ),
    );
  }

  /// Show confirmation dialog before cancelling
  void _showCancelDialog(BuildContext context, FieldVisitModel visit) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Visit Request?'),
        content: const Text(
          'Are you sure you want to cancel this visit request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelVisit(visit.id);
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

/// Visit card widget showing visit summary and status
class _VisitCard extends StatelessWidget {
  final FieldVisitModel visit;
  final VoidCallback? onCancel;

  const _VisitCard({required this.visit, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Expert name + Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Expert: ${visit.expertName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(status: visit.status),
              ],
            ),
            const SizedBox(height: 10),

            // Crop + Problem
            _buildInfoRow(
              Icons.grass,
              '${visit.cropType} — ${visit.problemCategory}',
            ),
            const SizedBox(height: 6),

            // Preferred date
            _buildInfoRow(
              Icons.calendar_today,
              'Preferred: ${DateFormat('dd MMM yyyy').format(visit.preferredDate)}',
            ),

            // Confirmed date (if accepted)
            if (visit.confirmedDate != null) ...[
              const SizedBox(height: 6),
              _buildInfoRow(
                Icons.check_circle_outline,
                'Confirmed: ${DateFormat('dd MMM yyyy').format(visit.confirmedDate!)}',
              ),
            ],

            const SizedBox(height: 6),

            // Location
            _buildInfoRow(Icons.location_on_outlined, visit.fullAddress),

            // Expert notes (if completed)
            if (visit.expertNotes != null && visit.expertNotes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expert Notes:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      visit.expertNotes!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            // Cancel button (only for pending)
            if (onCancel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text(
                    'Cancel Request',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Color-coded status badge
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'accepted':
      case 'scheduled':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'rejected':
      case 'cancelled':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case 'completed':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    // Capitalize first letter
    final label = status.isNotEmpty
        ? '${status[0].toUpperCase()}${status.substring(1)}'
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
