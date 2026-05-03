import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_colors.dart';
import '../view_model/expert_dashboard_controller.dart';
import '../models/field_visit_model.dart';

/// ExpertDashboardView — Expert's main screen for managing field visits
/// Tabs: New Requests | Upcoming | Completed
///
/// Use the calendar icon in the AppBar to view slot-based consultation
/// appointments (ExpertAppointmentsView).
class ExpertDashboardView extends GetView<ExpertDashboardController> {
  const ExpertDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('seller_dashboard'.tr),
          centerTitle: true,
          actions: [
            Tooltip(
              message: 'My Consultations',
              child: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () =>
                    Get.toNamed(AppRoutes.EXPERT_APPOINTMENTS),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryGreen,
            tabs: [
              Obx(
                    () => Tab(
                  text: 'New (${controller.pendingVisits.length})',
                  icon: const Icon(Icons.notification_important_outlined),
                ),
              ),
              Obx(
                    () => Tab(
                  text: 'Upcoming (${controller.upcomingVisits.length})',
                  icon: const Icon(Icons.calendar_today),
                ),
              ),
              Obx(
                    () => Tab(
                  text: 'Done (${controller.completedVisits.length})',
                  icon: const Icon(Icons.check_circle_outline),
                ),
              ),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          return TabBarView(
            children: [
              // Tab 1: New Requests (pending)
              _buildVisitList(
                visits: controller.pendingVisits,
                emptyMessage: 'No new visit requests.',
                emptyIcon: Icons.inbox_outlined,
                showActions: true,
                actionType: _ActionType.acceptReject,
              ),

              // Tab 2: Upcoming (accepted/scheduled)
              _buildVisitList(
                visits: controller.upcomingVisits,
                emptyMessage: 'No upcoming visits.',
                emptyIcon: Icons.event_available,
                showActions: true,
                actionType: _ActionType.complete,
              ),

              // Tab 3: Completed
              _buildVisitList(
                visits: controller.completedVisits,
                emptyMessage: 'No completed visits yet.',
                emptyIcon: Icons.history,
                showActions: false,
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Build a scrollable list of visit cards
  Widget _buildVisitList({
    required RxList<FieldVisitModel> visits,
    required String emptyMessage,
    required IconData emptyIcon,
    bool showActions = false,
    _ActionType actionType = _ActionType.none,
  }) {
    if (visits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadAllVisits,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final visit = visits[index];
          return _ExpertVisitCard(
            visit: visit,
            showActions: showActions,
            actionType: actionType,
            onAccept: () => controller.acceptVisit(visit),
            onReject: () => _showRejectDialog(visit),
            onComplete: () => _showCompleteDialog(visit),
            onOpenMaps: () => controller.openInMaps(visit),
          );
        },
      ),
    );
  }

  /// Show reject confirmation dialog
  void _showRejectDialog(FieldVisitModel visit) {
    Get.dialog(
      AlertDialog(
        title: Text('delete'.tr),
        content: Text('Reject the visit request from ${visit.farmerName}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              controller.rejectVisit(visit);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Show complete visit dialog with notes input
  void _showCompleteDialog(FieldVisitModel visit) {
    controller.expertNotesController.clear();
    Get.dialog(
      AlertDialog(
        title: const Text('Complete Visit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add your notes and observations from the visit:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.expertNotesController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Write your observations, recommendations...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.completeVisit(visit);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text(
              'Mark Complete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action types for visit cards
enum _ActionType { none, acceptReject, complete }

/// Visit card for expert dashboard
class _ExpertVisitCard extends StatelessWidget {
  final FieldVisitModel visit;
  final bool showActions;
  final _ActionType actionType;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onComplete;
  final VoidCallback onOpenMaps;

  const _ExpertVisitCard({
    required this.visit,
    required this.showActions,
    required this.actionType,
    required this.onAccept,
    required this.onReject,
    required this.onComplete,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farmer name + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    visit.farmerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('dd MMM').format(visit.createdAt),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Crop & Problem
            _infoChip(
              Icons.grass,
              '${visit.cropType} — ${visit.problemCategory}',
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              visit.description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Images (if any)
            if (visit.imageUrls != null && visit.imageUrls!.isNotEmpty) ...[
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: visit.imageUrls!.length,
                  itemBuilder: (context, idx) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: visit.imageUrls![idx],
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Preferred date
            _infoChip(
              Icons.calendar_today,
              'Preferred: ${DateFormat('dd MMM yyyy').format(visit.preferredDate)}',
            ),
            const SizedBox(height: 6),

            // Address
            _infoChip(Icons.location_on_outlined, visit.fullAddress),
            const SizedBox(height: 6),

            // Farm size
            _infoChip(Icons.landscape, '${visit.farmSize} acres'),

            const SizedBox(height: 10),

            // Open in Maps button
            OutlinedButton.icon(
              onPressed: onOpenMaps,
              icon: const Icon(
                Icons.map,
                color: AppColors.primaryGreen,
                size: 18,
              ),
              label: const Text(
                'Open in Google Maps',
                style: TextStyle(color: AppColors.primaryGreen, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),

            // Expert notes (for completed visits)
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
                      'Your Notes:',
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

            // Action buttons
            if (showActions) ...[
              const SizedBox(height: 14),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  /// Build action buttons based on action type
  Widget _buildActionButtons() {
    switch (actionType) {
      case _ActionType.acceptReject:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                label: const Text(
                  'Accept',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close, color: Colors.red, size: 18),
                label: const Text(
                  'Reject',
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
        );

      case _ActionType.complete:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
            label: const Text(
              'Mark as Completed',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// Small info chip with icon
  Widget _infoChip(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
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
