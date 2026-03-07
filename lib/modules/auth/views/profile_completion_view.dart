import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';

/// ProfileCompletionView - Dynamic profile form based on selected role
/// Shows different fields for Farmer, Expert, and Company (Seller)
class ProfileCompletionView extends GetView<OnboardingController> {
  const ProfileCompletionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.goBackToRoleSelection,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========== HEADER ==========
                  _buildHeader(),

                  const SizedBox(height: 24),

                  // ========== DYNAMIC FORM BASED ON ROLE ==========
                  _buildDynamicForm(),

                  const SizedBox(height: 32),

                  // ========== SAVE BUTTON ==========
                  _buildSaveButton(),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Loading overlay — only this part is reactive
            Obx(() => controller.isLoading.value
                ? Container(
                    color: Colors.white.withValues(alpha: 0.7),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  /// Get app bar title based on role (localized)
  String _getAppBarTitle() {
    switch (controller.selectedRole.value) {
      case 'farmer':
        return 'farmer_profile'.tr;
      case 'expert':
        return 'expert_profile'.tr;
      case 'company':
        return 'business_profile'.tr;
      default:
        return 'complete_profile'.tr;
    }
  }

  /// Build header with role icon
  /// NOTE: No Obx needed — selectedRole is set before navigating here.
  Widget _buildHeader() {
    IconData icon;
    Color color;
    String message;

    switch (controller.selectedRole.value) {
      case 'farmer':
        icon = Icons.grass;
        color = AppConstants.primaryGreen;
        message = 'tell_about_farm'.tr;
        break;
      case 'expert':
        icon = Icons.school;
        color = Colors.blue[700]!;
        message = 'share_expertise'.tr;
        break;
      case 'company':
        icon = Icons.store;
        color = Colors.orange[700]!;
        message = 'tell_about_business'.tr;
        break;
      default:
        icon = Icons.person;
        color = AppConstants.primaryGreen;
        message = 'complete_your_profile'.tr;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'fields_required'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build dynamic form based on selected role
  /// NOTE: No Obx needed here — selectedRole is set before navigating to this
  /// screen and does not change. Wrapping in Obx caused nested-Obx issues
  /// with the crops grid Obx inside _buildFarmerForm().
  Widget _buildDynamicForm() {
    switch (controller.selectedRole.value) {
      case 'farmer':
        return _buildFarmerForm();
      case 'expert':
        return _buildExpertForm();
      case 'company':
        return _buildCompanyForm();
      default:
        return const SizedBox();
    }
  }

  // ========== FARMER FORM ==========
  Widget _buildFarmerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Field
        CustomTextField(
          controller: controller.nameController,
          labelText: '${'full_name'.tr} *',
          hintText: 'enter_full_name'.tr,
          prefixIcon: Icons.person,
        ),
        const SizedBox(height: 16),

        // Phone Field
        CustomTextField(
          controller: controller.phoneController,
          labelText: 'phone_number'.tr,
          hintText: 'enter_phone'.tr,
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // Location Field
        CustomTextField(
          controller: controller.locationController,
          labelText: 'farm_location'.tr,
          hintText: 'enter_farm_location'.tr,
          prefixIcon: Icons.location_on,
        ),
        const SizedBox(height: 16),

        // Farm Size Field
        CustomTextField(
          controller: controller.farmSizeController,
          labelText: 'farm_size'.tr,
          hintText: 'enter_farm_size'.tr,
          prefixIcon: Icons.square_foot,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),

        // Crops Section
        _buildCropsSection(),
      ],
    );
  }

  /// Build crops multi-select section for farmers
  Widget _buildCropsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'crops_grown'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'select_crops'.tr,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 12),

        // Crops Grid — Obx wraps ONLY the grid; selectedCrops is the reactive trigger
        Obx(() {
          // Force reactive dependency by reading selectedCrops.length
          final _ = controller.selectedCrops.length;
          return LayoutBuilder(
            builder: (context, constraints) {
              final r = ResponsiveHelper.of(context);
              // Dynamic columns: 2 on phones, 3+ on tablets
              final crossAxisCount = r.gridCrossAxisCount(minItemWidth: 150);
              final aspectRatio = r.isSmallPhone ? 3.5 : 3.0;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: r.scale(12),
                  mainAxisSpacing: r.scale(12),
                ),
          itemCount: OnboardingController.availableCrops.length,
          itemBuilder: (context, index) {
            final crop = OnboardingController.availableCrops[index];
            final isSelected = controller.selectedCrops.contains(crop);

            return InkWell(
              onTap: () => controller.toggleCropSelection(crop),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryGreen.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppConstants.primaryGreen
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected
                          ? AppConstants.primaryGreen
                          : Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        crop,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppConstants.darkGreen
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
              );
            },
          );
        }),
      ],
    );
  }

  // ========== EXPERT FORM ==========
  Widget _buildExpertForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Field
        CustomTextField(
          controller: controller.nameController,
          labelText: '${'full_name'.tr} *',
          hintText: 'enter_full_name'.tr,
          prefixIcon: Icons.person,
        ),
        const SizedBox(height: 16),

        // Phone Field
        CustomTextField(
          controller: controller.phoneController,
          labelText: 'phone_number'.tr,
          hintText: 'enter_phone'.tr,
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // Location Field
        CustomTextField(
          controller: controller.locationController,
          labelText: 'location'.tr,
          hintText: 'enter_location'.tr,
          prefixIcon: Icons.location_on,
        ),
        const SizedBox(height: 16),

        // Specialization Dropdown
        _buildSpecializationDropdown(),
        const SizedBox(height: 16),

        // Years of Experience
        CustomTextField(
          controller: controller.yearsExperienceController,
          labelText: 'years_experience'.tr,
          hintText: 'enter_years_experience'.tr,
          prefixIcon: Icons.work_history,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        // Certifications
        CustomTextField(
          controller: controller.certificationsController,
          labelText: 'certifications'.tr,
          hintText: 'enter_certifications'.tr,
          prefixIcon: Icons.card_membership,
        ),
        const SizedBox(height: 16),

        // Bio
        CustomTextField(
          controller: controller.bioController,
          labelText: 'short_bio'.tr,
          hintText: 'bio_hint'.tr,
          prefixIcon: Icons.description,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Available for Consultation Toggle
        _buildConsultationToggle(),
      ],
    );
  }

  /// Build specialization dropdown for experts
  Widget _buildSpecializationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'specialization'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: controller.selectedSpecialization.value.isEmpty
              ? null
              : controller.selectedSpecialization.value,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.workspace_premium),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          hint: Text('select_specialization'.tr),
          items: OnboardingController.expertSpecializations
              .map((spec) => DropdownMenuItem(
                    value: spec,
                    child: Text(spec),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              controller.selectedSpecialization.value = value;
            }
          },
        ),
      ],
    );
  }

  /// Build consultation availability toggle
  /// NOTE: Obx wraps ONLY the Switch — not the surrounding static container.
  Widget _buildConsultationToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'available_appointments'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'let_farmers_book'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Obx(() => Switch(
            value: controller.isAvailableForConsultation.value,
            onChanged: (value) {
              controller.isAvailableForConsultation.value = value;
            },
            activeTrackColor: AppConstants.primaryGreen.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return AppConstants.primaryGreen;
              }
              return Colors.grey;
            }),
          )),
        ],
      ),
    );
  }

  // ========== COMPANY FORM ==========
  Widget _buildCompanyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company Name Field
        CustomTextField(
          controller: controller.companyNameController,
          labelText: 'company_name'.tr,
          hintText: 'enter_company_name'.tr,
          prefixIcon: Icons.business,
        ),
        const SizedBox(height: 16),

        // Owner Name Field
        CustomTextField(
          controller: controller.ownerNameController,
          labelText: 'owner_name'.tr,
          hintText: 'enter_owner_name'.tr,
          prefixIcon: Icons.person,
        ),
        const SizedBox(height: 16),

        // Phone Field
        CustomTextField(
          controller: controller.phoneController,
          labelText: 'phone_number'.tr,
          hintText: 'business_phone'.tr,
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // Business Location Field
        CustomTextField(
          controller: controller.locationController,
          labelText: 'business_location'.tr,
          hintText: 'enter_business_location'.tr,
          prefixIcon: Icons.location_on,
        ),
        const SizedBox(height: 16),

        // Business Type Dropdown
        _buildBusinessTypeDropdown(),
        const SizedBox(height: 16),

        // Years in Business
        CustomTextField(
          controller: controller.yearsInBusinessController,
          labelText: 'years_in_business'.tr,
          hintText: 'how_many_years'.tr,
          prefixIcon: Icons.work_history,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        // License Number (Optional)
        CustomTextField(
          controller: controller.licenseNumberController,
          labelText: 'license_number'.tr,
          hintText: 'enter_license_number'.tr,
          prefixIcon: Icons.badge,
        ),
        const SizedBox(height: 16),

        // Business Description
        CustomTextField(
          controller: controller.businessDescriptionController,
          labelText: 'business_description'.tr,
          hintText: 'business_desc_hint'.tr,
          prefixIcon: Icons.description,
          maxLines: 3,
        ),
      ],
    );
  }

  /// Build business type dropdown for company/seller
  Widget _buildBusinessTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'business_type'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: controller.selectedBusinessType.value.isEmpty
              ? null
              : controller.selectedBusinessType.value,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          hint: Text('select_business_type'.tr),
          items: OnboardingController.businessTypes
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              controller.selectedBusinessType.value = value;
            }
          },
        ),
      ],
    );
  }

  /// Build save button
  Widget _buildSaveButton() {
    return Obx(() => CustomButton(
      text: 'save_continue'.tr,
      onPressed: controller.saveProfile,
      isLoading: controller.isLoading.value,
    ));
  }
}




