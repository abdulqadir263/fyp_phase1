import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/localization/language_controller.dart';

// Profile screen ka UI
class ProfileView extends GetView<ProfileController> {
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
        child: ResponsiveHelper.tabletCenter(
          child: Obx(() {
        if (controller.user.value == null) {
          return Center(child: Text('user_data_not_found'.tr));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Picture Section
              _buildProfilePictureSection(),

              SizedBox(height: 24),

              // User Information Form
              _buildUserInformationForm(),

              SizedBox(height: 24),

              // ========== LANGUAGE TOGGLE SECTION ==========
              _buildLanguageToggle(),

              SizedBox(height: 32),
              if (controller.isEditing.value) _buildUserTypeSection(),

              SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        );
      }),
        ),
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
              backgroundColor: Colors.grey[300],
              backgroundImage: hasImage
                  ? NetworkImage(controller.profileImageUrl.value) as ImageProvider
                  : null,
              child: !hasImage
                  ? Icon(Icons.person, size: 60, color: Colors.white)
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
                  padding: EdgeInsets.all(8),
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
                    padding: EdgeInsets.all(8),
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
      children: [
        // Name Field
        CustomTextField(
          controller: controller.nameController,
          labelText: 'full_name'.tr,
          prefixIcon: Icons.person,
          enabled: controller.isEditing.value,
        ),
        SizedBox(height: 16),

        // Email Field
        CustomTextField(
          controller: controller.emailController,
          labelText: 'email'.tr,
          prefixIcon: Icons.email,
          enabled: false, // Email change nahi ho sakta
        ),
        SizedBox(height: 16),

        // Phone Field
        CustomTextField(
          controller: controller.phoneController,
          labelText: 'phone_number'.tr,
          prefixIcon: Icons.phone,
          enabled: controller.isEditing.value,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16),

        // Location Field (farmers only)
        if (controller.userType.value == 'farmer') ...[
          CustomTextField(
            controller: controller.locationController,
            labelText: 'farm_location'.tr,
            prefixIcon: Icons.location_on,
            enabled: controller.isEditing.value,
          ),
          SizedBox(height: 16),

          // Farm Size Field
          CustomTextField(
            controller: controller.farmSizeController,
            labelText: 'farm_size'.tr,
            prefixIcon: Icons.square_foot,
            enabled: controller.isEditing.value,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
        ],

        // Specialization Field (experts only)
        if (controller.userType.value == 'expert') ...[
          CustomTextField(
            controller: controller.specializationController,
            labelText: 'specialization'.tr,
            prefixIcon: Icons.workspace_premium,
            enabled: controller.isEditing.value,
          ),
          SizedBox(height: 16),
        ],

        // Company Name Field (companies only)
        if (controller.userType.value == 'company') ...[
          CustomTextField(
            controller: controller.companyNameController,
            labelText: 'company_name'.tr,
            prefixIcon: Icons.business,
            enabled: controller.isEditing.value,
          ),
          SizedBox(height: 16),
        ],
      ],
    );
  }

  // User type section
  Widget _buildUserTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'user_type'.tr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
              value: controller.userType.value,  // renamed from selectedUserType
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: controller.changeUserType,  // renamed from onUserTypeChanged
              items: [
                DropdownMenuItem(value: 'farmer', child: Text('farmer'.tr)),
                DropdownMenuItem(value: 'expert', child: Text('agricultural_expert'.tr)),
                DropdownMenuItem(value: 'company', child: Text('company'.tr)),
              ],
            )),
          ],
        ),
      ),
    );
  }

  // Action buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        // "Skip" button — only shown when profile is incomplete
        if (!controller.isEditing.value && controller.isProfileIncomplete) ...[
          OutlinedButton(
            onPressed: controller.skipProfileSetup,  // renamed from createProfileLater
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey),
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text('create_profile_later'.tr),
          ),
          SizedBox(height: 12),
        ],

        // Cancel Button (sirf edit mode mein dikhega)
        if (controller.isEditing.value)
          CustomButton(
            text: 'cancel'.tr,
            onPressed: controller.toggleEditMode,
            color: Colors.grey,
          ),

        if (controller.isEditing.value) SizedBox(height: 12),

        // Delete Account Button
        OutlinedButton(
          onPressed: controller.deleteAccount,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red),
            minimumSize: Size(double.infinity, 50),
          ),
          child: Text('delete_account'.tr, style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  /// Language toggle section — allows switching between English and Urdu
  Widget _buildLanguageToggle() {
    final langController = Get.find<LanguageController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
      ),
    );
  }

}