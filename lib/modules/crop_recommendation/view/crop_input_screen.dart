import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../view_model/crop_recommendation_controller.dart';

/// Input screen for crop recommendation.
/// User enters N, P, K, Temperature, Humidity, pH, Rainfall.
class CropInputScreen extends GetView<CropRecommendationController> {
  const CropInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('crop_recommendation_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => Get.toNamed('/crop-recommendation/history'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveHelper.tabletCenter(
          child: Form(
            key: controller.formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: 20),

                // Soil Nutrients Card
                _buildSectionCard(
                  context,
                  title: 'Soil Nutrients',
                  icon: Icons.grass_rounded,
                  children: [
                    _buildInputField(
                      controller: controller.nController,
                      label: 'Nitrogen (N)',
                      hint: 'e.g. 50',
                      suffix: 'mg/kg',
                      icon: Icons.science_rounded,
                      validator: (v) => controller.validateField(v, 'Nitrogen'),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: controller.pController,
                      label: 'Phosphorus (P)',
                      hint: 'e.g. 40',
                      suffix: 'mg/kg',
                      icon: Icons.science_rounded,
                      validator: (v) =>
                          controller.validateField(v, 'Phosphorus'),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: controller.kController,
                      label: 'Potassium (K)',
                      hint: 'e.g. 45',
                      suffix: 'mg/kg',
                      icon: Icons.science_rounded,
                      validator: (v) =>
                          controller.validateField(v, 'Potassium'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Environmental Conditions Card
                _buildSectionCard(
                  context,
                  title: 'Environmental Conditions',
                  icon: Icons.wb_sunny_rounded,
                  children: [
                    _buildInputField(
                      controller: controller.temperatureController,
                      label: 'Temperature',
                      hint: 'e.g. 25',
                      suffix: '°C',
                      icon: Icons.thermostat_rounded,
                      validator: (v) =>
                          controller.validateField(v, 'Temperature'),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: controller.humidityController,
                      label: 'Humidity',
                      hint: 'e.g. 70',
                      suffix: '%',
                      icon: Icons.water_drop_rounded,
                      validator: (v) => controller.validateField(v, 'Humidity'),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: controller.rainfallController,
                      label: 'Rainfall',
                      hint: 'e.g. 200',
                      suffix: 'mm',
                      icon: Icons.umbrella_rounded,
                      validator: (v) => controller.validateField(v, 'Rainfall'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Soil pH Card
                _buildSectionCard(
                  context,
                  title: 'Soil Property',
                  icon: Icons.landslide_rounded,
                  children: [
                    _buildInputField(
                      controller: controller.phController,
                      label: 'pH Level',
                      hint: 'e.g. 6.5',
                      suffix: 'pH',
                      icon: Icons.opacity_rounded,
                      validator: (v) => controller.validateField(v, 'pH Level'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                Obx(
                  () => SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.getRecommendation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.eco_rounded, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Get Recommendation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: AppColors.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Crop Advisor',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter your soil and climate data to get the best crop recommendations.',
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

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
