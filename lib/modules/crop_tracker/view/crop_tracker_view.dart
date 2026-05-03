import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../view_model/crop_tracker_view_model.dart';
import '../models/crop_model.dart';
import '../widgets/crop_card_widget.dart';
import '../widgets/stats_row_widget.dart';
import 'add_crop_view.dart';
import 'crop_detail_view.dart';
import '../../../core/constants/app_constants.dart';

class CropTrackerView extends GetView<CropTrackerViewModel> {
  const CropTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppConstants.primaryGreen,
        title: const Text(
          'Crop Tracker',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: controller.loadCrops,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
                color: AppConstants.primaryGreen),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadCrops,
          color: AppConstants.primaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                StatsRowWidget(
                  activeCrops: controller.activeCrops,
                  totalIncome: controller.totalIncome,
                  totalProfit: controller.totalProfit,
                ),
                const SizedBox(height: 20),

                // Filters
                _buildFilters(),
                const SizedBox(height: 16),

                // List
                controller.filteredCrops.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  itemCount:
                  controller.filteredCrops.length,
                  itemBuilder: (_, i) {
                    final crop =
                    controller.filteredCrops[i];
                    return CropCardWidget(
                      crop: crop,
                      onTap: () => Get.to(
                            () => CropDetailView(
                            cropId: crop.id),
                        transition:
                        Transition.rightToLeft,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryGreen,
        onPressed: () => Get.to(
              () => const AddCropView(),
          transition: Transition.downToUp,
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Crop',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'active', 'label': 'Active'},
      {'key': 'harvested', 'label': 'Harvested'},
    ];
    return Obx(() => Row(
      children: filters.map((f) {
        final isSelected =
            controller.selectedFilter.value == f['key'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(f['label']!),
            selected: isSelected,
            onSelected: (_) =>
                controller.setFilter(f['key']!),
            selectedColor: AppConstants.primaryGreen
                .withValues(alpha: 0.15),
            checkmarkColor: AppConstants.primaryGreen,
            labelStyle: TextStyle(
              color: isSelected
                  ? AppConstants.primaryGreen
                  : Colors.grey.shade600,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    ));
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Icon(Icons.agriculture,
            size: 80,
            color: AppConstants.primaryGreen
                .withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text('No crops found',
            style: TextStyle(
                fontSize: 18, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        Text('Tap + to add a crop',
            style: TextStyle(color: Colors.grey.shade400)),
      ]),
    ),
  );
}