import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../view_model/appointment_controller.dart';

/// ExpertProfileView — Shows expert details and "Request Visit" button
/// Farmer sees expert's specialization, bio, certifications, etc.
class ExpertProfileView extends GetView<AppointmentController> {
  const ExpertProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('profile'.tr), centerTitle: true),
      body: SafeArea(
        top: false,
        child: ResponsiveHelper.tabletCenter(
          child: Obx(() {
            final expert = controller.selectedExpert.value;

            if (expert == null) {
              return const Center(child: Text('No expert selected.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Expert avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.lightGreen,
                    child: Text(
                      (expert.name.isNotEmpty ? expert.name[0] : 'E')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Expert name
                  Text(
                    expert.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Specialization badge
                  if (expert.specialization != null &&
                      expert.specialization!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        expert.specialization!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Info cards
                  _buildInfoRow(
                    Icons.access_time,
                    'Experience',
                    '${expert.yearsOfExperience ?? 0} years',
                  ),

                  if (expert.location != null && expert.location!.isNotEmpty)
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      'Location',
                      expert.location!,
                    ),

                  if (expert.phone.isNotEmpty)
                    _buildInfoRow(Icons.phone_outlined, 'Phone', expert.phone),

                  if (expert.certifications != null &&
                      expert.certifications!.isNotEmpty)
                    _buildInfoRow(
                      Icons.verified_outlined,
                      'Certifications',
                      expert.certifications!,
                    ),

                  if (expert.isAvailableForConsultation == true)
                    _buildInfoRow(
                      Icons.check_circle_outline,
                      'Available for Consultation',
                      'Yes',
                    ),

                  if (expert.isAvailableForConsultation == false)
                    _buildInfoRow(
                      Icons.cancel_outlined,
                      'Available for Consultation',
                      'No',
                    ),

                  // Bio section
                  if (expert.bio != null && expert.bio!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        expert.bio!,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Request Visit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed('/appointments/request-visit');
                      },
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Request Farm Visit',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // View my visits button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.toNamed('/appointments/my-visits');
                      },
                      icon: const Icon(
                        Icons.list_alt,
                        color: AppColors.primaryGreen,
                      ),
                      label: const Text(
                        'View My Visits',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Build a single info row with icon, label, and value
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
