import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../../app/widgets/custom_button.dart';
import '../../../../app/widgets/custom_text_field.dart';

// Profile screen ka UI
class ProfileView extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        centerTitle: true,
        actions: [
          // Edit/Save button
          Obx(() => IconButton(
            icon: Icon(controller.isEditing.value ? Icons.save : Icons.edit),
            onPressed: controller.isEditing.value ? controller.updateProfile : controller.toggleEditMode,
            tooltip: controller.isEditing.value ? 'Save' : 'Edit',
          )),
        ],
      ),

      body: Obx(() {
        if (controller.user.value == null) {
          return Center(child: Text('User data not found.'));
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

              SizedBox(height: 32),

              // User Type Section (sirf edit mode mein dikhega)
              if (controller.isEditing.value) _buildUserTypeSection(),

              SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        );
      }),
    );
  }

  // Profile picture section
  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        children: [
          // Profile Image
          Obx(() {
            // Check if image path is not empty
            bool hasImage = controller.profileImagePath.value.isNotEmpty;

            return CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: hasImage
                  ? NetworkImage(controller.profileImagePath.value) as ImageProvider
                  : null,
              child: !hasImage
                  ? Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            );
          }),

          // Loading indicator for image upload
          Obx(() {
            if (controller.isUploadingImage.value) {
              return Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            }

            // Camera Icon (sirf edit mode mein dikhega)
            if (controller.isEditing.value && !controller.isUploadingImage.value) {
              return Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: controller.pickProfileImage,
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

            return SizedBox.shrink(); // Empty widget when not editing
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
          labelText: 'Full Name',
          prefixIcon: Icons.person,
          enabled: controller.isEditing.value,
        ),
        SizedBox(height: 16),

        // Email Field
        CustomTextField(
          controller: controller.emailController,
          labelText: 'Email',
          prefixIcon: Icons.email,
          enabled: false, // Email change nahi ho sakta
        ),
        SizedBox(height: 16),

        // Phone Field
        CustomTextField(
          controller: controller.phoneController,
          labelText: 'Phone Number',
          prefixIcon: Icons.phone,
          enabled: controller.isEditing.value,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16),

        // Location Field (sirf farmers ke liye)
        if (controller.selectedUserType.value == 'farmer') ...[
          CustomTextField(
            controller: controller.locationController,
            labelText: 'Farm Location',
            prefixIcon: Icons.location_on,
            enabled: controller.isEditing.value,
          ),
          SizedBox(height: 16),

          // Farm Size Field
          CustomTextField(
            controller: controller.farmSizeController,
            labelText: 'Farm Size (acres)',
            prefixIcon: Icons.square_foot,
            enabled: controller.isEditing.value,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
        ],

        // Specialization Field (sirf experts ke liye)
        if (controller.selectedUserType.value == 'expert') ...[
          CustomTextField(
            controller: controller.specializationController,
            labelText: 'Specialization',
            prefixIcon: Icons.workspace_premium,
            enabled: controller.isEditing.value,
          ),
          SizedBox(height: 16),
        ],

        // Company Name Field (sirf companies ke liye)
        if (controller.selectedUserType.value == 'company') ...[
          CustomTextField(
            controller: controller.companyNameController,
            labelText: 'Company Name',
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
              'User Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedUserType.value,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: controller.onUserTypeChanged,
              items: [
                DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                DropdownMenuItem(value: 'expert', child: Text('Agricultural Expert')),
                DropdownMenuItem(value: 'company', child: Text('Company')),
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
        // ✅ NEW: Create Profile Later Button (sirf pehli bar ke liye)
        if (!controller.isEditing.value && _isFirstTimeLogin()) ...[
          OutlinedButton(
            onPressed: controller.createProfileLater,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey),
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text('Create Profile Later'),
          ),
          SizedBox(height: 12),
        ],

        // Cancel Button (sirf edit mode mein dikhega)
        if (controller.isEditing.value)
          CustomButton(
            text: 'Cancel',
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
          child: Text('Delete Account', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  // ✅ NEW: Check if it's first time login
  bool _isFirstTimeLogin() {
    // Simple check - if profile is incomplete, it's likely first time
    final user = controller.user.value;
    if (user == null) return false;

    switch (user.userType) {
      case 'farmer':
        return user.location == null || user.location!.isEmpty;
      case 'expert':
        return user.specialization == null || user.specialization!.isEmpty;
      case 'company':
        return user.companyName == null || user.companyName!.isEmpty;
      default:
        return false;
    }
  }
}