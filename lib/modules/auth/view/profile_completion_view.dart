import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../view_model/onboarding_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';

class ProfileCompletionView extends GetView<OnboardingController> {
  const ProfileCompletionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Obx(() => Text(_getAppBarTitle(),style: TextStyle(color: Colors.green),)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.green,),
          onPressed: controller.goBackToRoleSelection,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Form wraps all fields — enables validator + red border on submit
            Form(
              key: controller.formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildDynamicForm(),
                        const SizedBox(height: 16),
                        _buildActionCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Obx(
                  () => controller.isLoading.value
                  ? Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const Center(child: CircularProgressIndicator()),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (controller.selectedRole.value) {
      case 'farmer':  return 'farmer_profile'.tr;
      case 'expert':  return 'expert_profile'.tr;
      case 'company': return 'business_profile'.tr;
      default:        return 'complete_profile'.tr;
    }
  }

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
        color = const Color(0xFF1565C0);
        message = 'share_expertise'.tr;
        break;
      case 'company':
        icon = Icons.store;
        color = const Color(0xFFE65100);
        message = 'tell_about_business'.tr;
        break;
      default:
        icon = Icons.person;
        color = AppConstants.primaryGreen;
        message = 'complete_your_profile'.tr;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                const SizedBox(height: 2),
                Text('fields_required'.tr,
                    style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicForm() {
    return Obx(() {
      final Widget content;
      switch (controller.selectedRole.value) {
        case 'farmer':  content = _buildFarmerForm();  break;
        case 'expert':  content = _buildExpertForm();  break;
        case 'company': content = _buildCompanyForm(); break;
        default:        content = const SizedBox();
      }
      return _buildSectionCard(child: content);
    });
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  InputDecoration _dropdownDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppConstants.primaryGreen, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── FARMER ─────────────────────────────────────────────────────────────
  // Required: name*, phone*, location*, crops* | Optional: farmSize

  Widget _buildFarmerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: controller.nameController,
          labelText: '${'full_name'.tr} *',
          hintText: 'enter_full_name'.tr,
          prefixIcon: Icons.person,
          validator: controller.validateName,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.phoneController,
          labelText: '${'phone_number'.tr} *',
          hintText: 'enter_phone'.tr,
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: controller.validatePhoneRequired,
          // Only digits, max 11
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.locationController,
          labelText: '${'farm_location'.tr} *',
          hintText: 'enter_farm_location'.tr,
          prefixIcon: Icons.location_on,
          validator: controller.validateRequired,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.farmSizeController,
          labelText: 'farm_size'.tr,
          hintText: 'enter_farm_size'.tr,
          prefixIcon: Icons.square_foot,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          validator: controller.validateFarmSize,
        ),
        const SizedBox(height: 20),
        _buildCropsSection(),
      ],
    );
  }

  Widget _buildCropsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${'crops_grown'.tr} *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text('select_crops'.tr,
            style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        const SizedBox(height: 10),
        Obx(() {
          final _ = controller.selectedCrops.length;
          return LayoutBuilder(
            builder: (context, constraints) {
              final r = ResponsiveHelper.of(context);
              final crossAxisCount = r.gridCrossAxisCount(minItemWidth: 150);
              final aspectRatio = r.isSmallPhone ? 3.5 : 3.0;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: r.scale(10),
                  mainAxisSpacing: r.scale(10),
                ),
                itemCount: OnboardingController.availableCrops.length,
                itemBuilder: (context, index) {
                  final crop = OnboardingController.availableCrops[index];
                  final isSelected = controller.selectedCrops.contains(crop);
                  return InkWell(
                    onTap: () => controller.toggleCropSelection(crop),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppConstants.primaryGreen.withValues(alpha: 0.06)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppConstants.primaryGreen : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isSelected ? AppConstants.primaryGreen : Colors.grey[400],
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(crop,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? AppConstants.darkGreen : Colors.grey[700],
                                )),
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

  // ── EXPERT ─────────────────────────────────────────────────────────────
  // Required: name*, specialization*, yearsExperience* | Optional: rest

  Widget _buildExpertForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: controller.nameController,
          labelText: '${'full_name'.tr} *',
          hintText: 'enter_full_name'.tr,
          prefixIcon: Icons.person,
          validator: controller.validateName,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.phoneController,
          labelText: 'phone_number'.tr,
          hintText: 'enter_phone'.tr,
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: controller.validatePhoneOptional,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.locationController,
          labelText: 'location'.tr,
          hintText: 'enter_location'.tr,
          prefixIcon: Icons.location_on,
        ),
        const SizedBox(height: 14),
        _buildSpecializationDropdown(),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.yearsExperienceController,
          labelText: '${'years_experience'.tr} *',
          hintText: 'enter_years_experience'.tr,
          prefixIcon: Icons.work_history,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: controller.validateYearsExperience,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.certificationsController,
          labelText: 'certifications'.tr,
          hintText: 'enter_certifications'.tr,
          prefixIcon: Icons.card_membership,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.bioController,
          labelText: 'short_bio'.tr,
          hintText: 'bio_hint'.tr,
          prefixIcon: Icons.description,
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        _buildConsultationToggle(),
      ],
    );
  }

  Widget _buildSpecializationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${'specialization'.tr} *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedSpecialization.value.isEmpty
              ? null : controller.selectedSpecialization.value,
          decoration: _dropdownDecoration(Icons.workspace_premium),
          hint: Text('select_specialization'.tr),
          items: OnboardingController.expertSpecializations
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) { if (v != null) controller.selectedSpecialization.value = v; },
        )),
      ],
    );
  }

  Widget _buildConsultationToggle() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('available_appointments'.tr,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text('let_farmers_book'.tr,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Obx(() => Switch(
            value: controller.isAvailableForConsultation.value,
            onChanged: (v) => controller.isAvailableForConsultation.value = v,
            activeTrackColor: AppConstants.primaryGreen.withValues(alpha: 0.4),
            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) return AppConstants.primaryGreen;
              return Colors.grey;
            }),
          )),
        ],
      ),
    );
  }

  // ── COMPANY ────────────────────────────────────────────────────────────
  // Required: companyName*, businessType* | Optional: rest

  Widget _buildCompanyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: controller.companyNameController,
          labelText: '${'company_name'.tr} *',
          hintText: 'enter_company_name'.tr,
          prefixIcon: Icons.business,
          validator: controller.validateRequired,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.ownerNameController,
          labelText: 'owner_name'.tr,
          hintText: 'enter_owner_name'.tr,
          prefixIcon: Icons.person,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.phoneController,
          labelText: 'phone_number'.tr,
          hintText: 'business_phone'.tr,
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: controller.validatePhoneOptional,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.locationController,
          labelText: 'business_location'.tr,
          hintText: 'enter_business_location'.tr,
          prefixIcon: Icons.location_on,
        ),
        const SizedBox(height: 14),
        _buildBusinessTypeDropdown(),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.yearsInBusinessController,
          labelText: 'years_in_business'.tr,
          hintText: 'how_many_years'.tr,
          prefixIcon: Icons.work_history,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: controller.validateYearsInBusiness,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: controller.licenseNumberController,
          labelText: 'license_number'.tr,
          hintText: 'enter_license_number'.tr,
          prefixIcon: Icons.badge,
        ),
        const SizedBox(height: 14),
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

  Widget _buildBusinessTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${'business_type'.tr} *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedBusinessType.value.isEmpty
              ? null : controller.selectedBusinessType.value,
          decoration: _dropdownDecoration(Icons.category),
          hint: Text('select_business_type'.tr),
          items: OnboardingController.businessTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) { if (v != null) controller.selectedBusinessType.value = v; },
        )),
      ],
    );
  }

  Widget _buildActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Obx(() => CustomButton(
        text: 'save_continue'.tr,
        onPressed: controller.saveProfile,
        isLoading: controller.isLoading.value,
      )),
    );
  }
}