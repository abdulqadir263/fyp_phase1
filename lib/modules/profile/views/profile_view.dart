import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/localization/language_controller.dart';

// Profile screen ka UI
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ FIXED: AppBar with proper layout
      appBar: AppBar(
        title: Text(
          'my_profile'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Edit/Save button
          Obx(() => IconButton(
            icon: Icon(
              controller.isEditing.value ? Icons.save : Icons.edit,
            ),
            onPressed: controller.isEditing.value ? controller.updateProfile : controller.toggleEditMode,
            tooltip: controller.isEditing.value ? 'save'.tr : 'edit'.tr,
          )),
        ],
      ),

      body: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6FFF8), Color(0xFFF9FAFF)],
            ),
          ),
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
                        const SizedBox(height: 20),
                        _buildSectionCard(child: _buildUserInformationForm()),
                        const SizedBox(height: 20),
                        _buildLanguageToggle(),
                        if (controller.isEditing.value) ...[
                          const SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
          Obx(() => Text(
                controller.nameController.text.isNotEmpty
                    ? controller.nameController.text
                    : 'full_name'.tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              )),
          const SizedBox(height: 4),
          Obx(() => Text(
                controller.userType.value.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              )),
        ],
      ),
    );
  }

  // Profile picture section
  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        children: [
          // Profile Image
          Obx(() {
            // profileImageUrl (renamed from profileImagePath)
            final hasImage = controller.profileImageUrl.value.isNotEmpty;
            return CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFFE9EDF4),
              backgroundImage: hasImage
                  ? NetworkImage(controller.profileImageUrl.value) as ImageProvider
                  : null,
              child: !hasImage
                  ? Icon(Icons.person, size: 58, color: Colors.grey[500])
                  : null,
            );
          }),

          // Loading indicator for image upload
          Obx(() {
            // Show camera icon only in edit mode, spinner while uploading
            if (controller.isUploadingImage.value)
              return Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2,
                    ),
                  ),
                ),
              );

            // Camera Icon (edit mode only)
            if (controller.isEditing.value && !controller.isUploadingImage.value) {
              return Positioned(
                bottom: 0, right: 0,
                child: InkWell(
                  onTap: controller.pickAndUploadImage,  // renamed
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(Get.context!).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              );
            }

            return SizedBox.shrink();
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Update your details to keep account information accurate.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        // Name Field
        CustomTextField(
          controller: controller.nameController,
          labelText: 'full_name'.tr,
          prefixIcon: Icons.person,
          enabled: controller.isEditing.value,
        ),
        const SizedBox(height: 16),

        // Email Field
        CustomTextField(
          controller: controller.emailController,
          labelText: 'email'.tr,
          prefixIcon: Icons.email,
          enabled: false, // Email change nahi ho sakta
        ),
        const SizedBox(height: 16),

        // Phone Field
        CustomTextField(
          controller: controller.phoneController,
          labelText: 'phone_number'.tr,
          prefixIcon: Icons.phone,
          enabled: controller.isEditing.value,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // Location Field (farmers only)
        if (controller.userType.value == 'farmer') ...[
          CustomTextField(
            controller: controller.locationController,
            labelText: 'farm_location'.tr,
            prefixIcon: Icons.location_on,
            enabled: controller.isEditing.value,
          ),
          const SizedBox(height: 16),

          // Farm Size Field
          CustomTextField(
            controller: controller.farmSizeController,
            labelText: 'farm_size'.tr,
            prefixIcon: Icons.square_foot,
            enabled: controller.isEditing.value,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
        ],

        // Specialization Field (experts only)
        if (controller.userType.value == 'expert') ...[
          CustomTextField(
            controller: controller.specializationController,
            labelText: 'specialization'.tr,
            prefixIcon: Icons.workspace_premium,
            enabled: controller.isEditing.value,
          ),
          const SizedBox(height: 16),
        ],

        // Company Name Field (companies only)
        if (controller.userType.value == 'company') ...[
          CustomTextField(
            controller: controller.companyNameController,
            labelText: 'company_name'.tr,
            prefixIcon: Icons.business,
            enabled: controller.isEditing.value,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // User type section
  Widget _buildUserTypeSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'user_type'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<String>(
                initialValue: controller.userType.value,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF9FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                onChanged: controller.changeUserType,
                items: [
                  DropdownMenuItem(value: 'farmer', child: Text('farmer'.tr)),
                  DropdownMenuItem(value: 'expert', child: Text('agricultural_expert'.tr)),
                  DropdownMenuItem(value: 'company', child: Text('company'.tr)),
                ],
              )),
        ],
      ),
    );
  }

  // Action buttons
  Widget _buildActionButtons() {
    return _buildSectionCard(
      child: Column(
        children: [
        // "Skip" button — only shown when profile is incomplete
        if (!controller.isEditing.value && controller.isProfileIncomplete) ...[
          OutlinedButton(
            onPressed: controller.skipProfileSetup,  // renamed from createProfileLater
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('create_profile_later'.tr),
          ),
          const SizedBox(height: 12),
        ],

        // Cancel Button (sirf edit mode mein dikhega)
        if (controller.isEditing.value)
          CustomButton(
            text: 'cancel'.tr,
            onPressed: controller.toggleEditMode,
            color: Colors.grey,
          ),

        if (controller.isEditing.value) const SizedBox(height: 12),

        // Delete Account Button
        OutlinedButton(
          onPressed: controller.deleteAccount,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.red.withValues(alpha: 0.03),
          ),
          child: Text('delete_account'.tr, style: TextStyle(color: Colors.red)),
        ),
      ],
      ),
    );
  }

  /// Language toggle section — allows switching between English and Urdu
  Widget _buildLanguageToggle() {
    final langController = Get.find<LanguageController>();
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'language'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Obx(() => Row(
                  children: [
                    const Icon(Icons.language, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        langController.isUrdu ? 'اردو' : 'English',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Switch(
                      value: langController.isUrdu,
                      onChanged: (_) => langController.toggleLanguage(),
                      activeTrackColor: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF4CAF50);
                        }
                        return Colors.grey;
                      }),
                    ),
                  ],
                )),
          const SizedBox(height: 4),
          Obx(() => Text(
                  langController.isUrdu
                      ? 'Switch to English'
                      : 'اردو میں تبدیل کریں',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                )),
        ],
      ),
    );
  }

}