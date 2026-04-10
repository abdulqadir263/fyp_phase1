import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../view_model/appointment_controller.dart';

/// RequestVisitView — Form for farmer to request a field visit
/// Fields: Crop Type, Problem, Description, Images, Date, Location, Address
class RequestVisitView extends GetView<AppointmentController> {
  const RequestVisitView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Field Visit'),
        centerTitle: true,
      ),
      body: ResponsiveHelper.tabletCenter(
        child: Obx(() {
          // Show loading overlay when submitting
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expert info header
                    if (controller.selectedExpert.value != null)
                      _buildExpertHeader(),

                    const SizedBox(height: 20),

                    // ── CROP TYPE ──
                    _buildSectionLabel('Crop Type *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.cropTypeController,
                      decoration: _inputDecoration(
                        hint: 'e.g., Wheat, Rice, Cotton',
                        icon: Icons.grass,
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),

                    const SizedBox(height: 20),

                    // ── PROBLEM CATEGORY ──
                    _buildSectionLabel('Problem Category *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue:
                          controller.selectedProblemCategory.value.isEmpty
                          ? null
                          : controller.selectedProblemCategory.value,
                      hint: const Text('Select problem type'),
                      decoration: _inputDecoration(icon: Icons.warning_amber),
                      items: AppointmentController.problemCategories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedProblemCategory.value = value;
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── DESCRIPTION ──
                    _buildSectionLabel('Describe the Problem *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.descriptionController,
                      decoration: _inputDecoration(
                        hint: 'Tell the expert what issue you are facing...',
                        icon: Icons.description,
                      ),
                      maxLines: 4,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 16),

                    // ── IMAGES (optional) ──
                    _buildSectionLabel('Photos (optional, max 3)'),
                    const SizedBox(height: 8),
                    _buildImagePicker(),

                    const SizedBox(height: 20),

                    // ── PREFERRED DATE ──
                    _buildSectionLabel('Preferred Visit Date *'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => controller.pickDate(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              controller.selectedDate.value != null
                                  ? DateFormat(
                                      'EEEE, dd MMM yyyy',
                                    ).format(controller.selectedDate.value!)
                                  : 'Tap to select date',
                              style: TextStyle(
                                fontSize: 16,
                                color: controller.selectedDate.value != null
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── FARM LOCATION ──
                    _buildSectionLabel('Farm Location'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.locationNameController,
                      decoration: _inputDecoration(
                        hint: 'Village/City name',
                        icon: Icons.place,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // GPS Capture button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: controller.getCurrentLocation,
                        icon: const Icon(
                          Icons.my_location,
                          color: AppColors.primaryGreen,
                        ),
                        label: Text(
                          controller.currentLat.value != 0.0
                              ? 'Location Captured ✓'
                              : 'Capture GPS Location *',
                          style: TextStyle(
                            color: controller.currentLat.value != 0.0
                                ? AppColors.primaryGreen
                                : Colors.grey.shade700,
                            fontSize: 15,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: controller.currentLat.value != 0.0
                                ? AppColors.primaryGreen
                                : Colors.grey.shade400,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    if (controller.currentLat.value != 0.0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Lat: ${controller.currentLat.value.toStringAsFixed(4)}, '
                          'Lng: ${controller.currentLng.value.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ── FULL ADDRESS ──
                    _buildSectionLabel('Full Address *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.addressController,
                      decoration: _inputDecoration(
                        hint: 'Street, Village, Tehsil, District',
                        icon: Icons.home_outlined,
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.words,
                    ),

                    const SizedBox(height: 20),

                    // ── FARM SIZE ──
                    _buildSectionLabel('Farm Size (acres) *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.farmSizeController,
                      decoration: _inputDecoration(
                        hint: 'e.g., 5',
                        icon: Icons.landscape,
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 32),

                    // ── SUBMIT BUTTON ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : controller.submitVisitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Request Field Visit',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Loading overlay
              if (controller.isSubmitting.value ||
                  controller.isUploadingImages.value)
                Container(
                  color: Colors.black26,
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              controller.isUploadingImages.value
                                  ? 'Uploading images...'
                                  : 'Sending request...',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  /// Expert header card showing who the request is for
  Widget _buildExpertHeader() {
    final expert = controller.selectedExpert.value!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGreen),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryGreen,
            child: Text(
              expert.name.isNotEmpty ? expert.name[0].toUpperCase() : 'E',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requesting visit from:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  expert.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build image picker section with thumbnails
  Widget _buildImagePicker() {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Existing selected images
            ...controller.selectedImages.asMap().entries.map((entry) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      entry.value,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => controller.removeImage(entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),

            // Add button (show only if < 3 images)
            if (controller.selectedImages.length < 3)
              GestureDetector(
                onTap: controller.pickImages,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate,
                    size: 32,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Section label text
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  /// Consistent input decoration
  InputDecoration _inputDecoration({String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.primaryGreen)
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
