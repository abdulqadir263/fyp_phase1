import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../controllers/crop_recommendation_controller.dart';
import '../models/recommendation_model.dart';

/// Displays the top 3 crop recommendations with suitability percentages.
class CropResultScreen extends GetView<CropRecommendationController> {
  const CropResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('results'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final recommendation = controller.currentRecommendation.value;
        if (recommendation == null) {
          return const Center(child: Text('No recommendation data available.'));
        }
        return _buildContent(context, recommendation);
      }),
    );
  }

  Widget _buildContent(
    BuildContext context,
    RecommendationModel recommendation,
  ) {
    final results = recommendation.results;

    return SafeArea(
      top: false,
      child: ResponsiveHelper.tabletCenter(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Success Header
            _buildSuccessHeader(context),
            const SizedBox(height: 20),

            // Input Summary Card
            _buildInputSummary(context, recommendation.input),
            const SizedBox(height: 20),

            // Results Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Top Recommendations',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Crop Result Cards
            ...List.generate(results.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCropCard(context, results[index], index),
              );
            }),

            const SizedBox(height: 12),

            // New Recommendation Button
            OutlinedButton.icon(
              onPressed: () {
                controller.clearForm();
                Get.back();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text('new_recommendation'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.primaryGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Complete!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on your soil and climate data, here are the best crops for you.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSummary(BuildContext context, CropInput input) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        leading: const Icon(Icons.tune_rounded, color: AppColors.primaryGreen),
        title: Text(
          'Your Input Parameters',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        children: [
          _inputRow('Nitrogen (N)', '${input.n}'),
          _inputRow('Phosphorus (P)', '${input.p}'),
          _inputRow('Potassium (K)', '${input.k}'),
          _inputRow('Temperature', '${input.temperature} °C'),
          _inputRow('Humidity', '${input.humidity} %'),
          _inputRow('pH Level', '${input.ph}'),
          _inputRow('Rainfall', '${input.rainfall} mm'),
        ],
      ),
    );
  }

  Widget _inputRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(BuildContext context, CropResult result, int rank) {
    final colors = [AppColors.primaryGreen, AppColors.info, AppColors.warning];
    final medals = ['🥇', '🥈', '🥉'];
    final color = colors[rank.clamp(0, 2)];
    final medal = medals[rank.clamp(0, 2)];
    final percentage = result.suitabilityPercentage;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank and Crop Name
            Row(
              children: [
                Text(medal, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rank #${rank + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _capitalize(result.cropName),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // Percentage Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 10,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),

            // Suitability label
            Text(
              'Suitability: ${percentage.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
