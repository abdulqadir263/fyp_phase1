import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../controllers/appointment_controller.dart';

/// ExpertListView — Shows list of available experts for farmers
/// Farmer can tap an expert to view profile and request a visit
class ExpertListView extends GetView<AppointmentController> {
  const ExpertListView({super.key});

  @override
  Widget build(BuildContext context) {
    // Load experts when view opens
    controller.loadExperts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find an Expert'),
        centerTitle: true,
      ),
      body: Obx(() {
        // Loading state
        if (controller.isLoadingExperts.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        // Empty state
        if (controller.experts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_search,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No experts available right now.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: controller.loadExperts,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        // Expert list
        return RefreshIndicator(
          onRefresh: controller.loadExperts,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.experts.length,
            itemBuilder: (context, index) {
              final expert = controller.experts[index];
              return _ExpertCard(
                expert: expert,
                onTap: () {
                  controller.selectExpert(expert);
                  Get.toNamed('/appointments/expert-profile');
                },
              );
            },
          ),
        );
      }),
    );
  }
}

/// Single expert card widget
class _ExpertCard extends StatelessWidget {
  final dynamic expert; // UserModel
  final VoidCallback onTap;

  const _ExpertCard({required this.expert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Expert avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.lightGreen,
                child: Text(
                  (expert.name.isNotEmpty ? expert.name[0] : 'E').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Expert info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expert.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (expert.specialization != null &&
                        expert.specialization!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.work_outline,
                              size: 16, color: AppColors.primaryGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              expert.specialization!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    if (expert.yearsOfExperience != null)
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${expert.yearsOfExperience} years experience',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    if (expert.location != null && expert.location!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              expert.location!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Arrow indicator
              const Icon(Icons.chevron_right, color: AppColors.primaryGreen),
            ],
          ),
        ),
      ),
    );
  }
}

