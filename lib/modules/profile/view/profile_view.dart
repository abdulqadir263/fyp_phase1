import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../view_model/profile_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/localization/language_controller.dart';
import '../../../core/constants/app_constants.dart';

/// Clean, flat profile view
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'my_profile'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(controller.isEditing.value ? Icons.save : Icons.edit),
              onPressed: controller.isEditing.value
                  ? controller.updateProfile
                  : controller.toggleEditMode,
              tooltip: controller.isEditing.value ? 'save'.tr : 'edit'.tr,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveHelper.tabletCenter(
          child: Obx(() {
            if (controller.user.value == null) {
              return Center(child: Text('user_data_not_found'.tr));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    children: [
                      _buildProfileHeaderCard(),
                      const SizedBox(height: 16),
                      _buildSectionCard(child: _buildUserInformationForm()),
                      const SizedBox(height: 16),
                      _buildLanguageToggle(),
                      if (controller.isEditing.value) ...[
                        const SizedBox(height: 16),
                        _buildUserTypeSection(),
                      ],
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
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

  Widget _buildProfileHeaderCard() {
    return _buildSectionCard(
      child: Column(
        children: [
          _buildProfilePictureSection(),
          const SizedBox(height: 14),
          Obx(
            () => Text(
              controller.nameController.text.isNotEmpty
                  ? controller.nameController.text
                  : 'full_name'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              controller.userType.value.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Profile picture section - cleaner state loading
  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        children: [
          Obx(() {
            final hasImage = controller.profileImageUrl.value.isNotEmpty;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: const Color(0xFFF1F3F5),
                backgroundImage: hasImage
                    ? NetworkImage(controller.profileImageUrl.value)
                        as ImageProvider
                    : null,
                child: !hasImage
                    ? Icon(Icons.person, size: 48, color: Colors.grey[400])
                    : null,
              ),
            );
          }),

          // Camera / Upload indicator
          Obx(() {
            if (controller.isUploadingImage.value) {
              return Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            }

            if (controller.isEditing.value &&
                !controller.isUploadingImage.value) {
              return Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: controller.pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  // User information form
  Widget _buildUserInformationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'my_profile'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Update your details to keep account information accurate.',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        const SizedBox(height: 20),

        CustomTextField(
          controller: controller.nameController,
          labelText: 'full_name'.tr,
          prefixIcon: Icons.person_outline,
          enabled: controller.isEditing.value,
        ),
        const SizedBox(height: 14),

        CustomTextField(
          controller: controller.emailController,
          labelText: 'email'.tr,
          prefixIcon: Icons.email_outlined,
          enabled: false,
        ),
        const SizedBox(height: 14),

        CustomTextField(
          controller: controller.phoneController,
          labelText: 'phone_number'.tr,
          prefixIcon: Icons.phone_outlined,
          enabled: controller.isEditing.value,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),

        // Location Field (farmers only)
        if (controller.userType.value == 'farmer') ...[
          CustomTextField(
            controller: controller.locationController,
            labelText: 'farm_location'.tr,
            prefixIcon: Icons.location_on_outlined,
            enabled: controller.isEditing.value,
          ),
          const SizedBox(height: 14),

          CustomTextField(
            controller: controller.farmSizeController,
            labelText: 'farm_size'.tr,
            prefixIcon: Icons.square_foot_outlined,
            enabled: controller.isEditing.value,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
        ],

        // Specialization Field (experts only)
        if (controller.userType.value == 'expert') ...[
          CustomTextField(
            controller: controller.specializationController,
            labelText: 'specialization'.tr,
            prefixIcon: Icons.workspace_premium_outlined,
            enabled: controller.isEditing.value,
          ),
          const SizedBox(height: 14),
        ],

        // Company Name Field (companies only)
        if (controller.userType.value == 'company') ...[
          CustomTextField(
            controller: controller.companyNameController,
            labelText: 'company_name'.tr,
            prefixIcon: Icons.business_outlined,
            enabled: controller.isEditing.value,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildUserTypeSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'user_type'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.userType.value,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppConstants.primaryGreen,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: controller.changeUserType,
              items: [
                DropdownMenuItem(value: 'farmer', child: Text('farmer'.tr)),
                DropdownMenuItem(
                  value: 'expert',
                  child: Text('agricultural_expert'.tr),
                ),
                DropdownMenuItem(value: 'company', child: Text('company'.tr)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Action buttons
  Widget _buildActionButtons() {
    return _buildSectionCard(
      child: Column(
        children: [
          if (!controller.isEditing.value &&
              controller.isProfileIncomplete) ...[
            OutlinedButton(
              onPressed: controller.skipProfileSetup,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                foregroundColor: Colors.grey[700],
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'create_profile_later'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (controller.isEditing.value)
            CustomButton(
              text: 'cancel'.tr,
              onPressed: controller.toggleEditMode,
              color: Colors.grey[700],
            ),

          if (controller.isEditing.value) const SizedBox(height: 12),

          OutlinedButton(
            onPressed: controller.deleteAccount,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.red.withValues(alpha: 0.03),
            ),
            child: Text(
              'delete_account'.tr,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle() {
    final langController = Get.find<LanguageController>();
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'language'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Obx(
              () => Row(
                children: [
                  Icon(Icons.language, color: Colors.grey[500], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          langController.isUrdu ? 'اردو' : 'English',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          langController.isUrdu
                              ? 'Switch to English'
                              : 'اردو میں تبدیل کریں',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: langController.isUrdu,
                    onChanged: (_) => langController.toggleLanguage(),
                    activeTrackColor: AppConstants.primaryGreen.withValues(
                        alpha: 0.4),
                    thumbColor:
                        WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppConstants.primaryGreen;
                      }
                      return Colors.grey;
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
