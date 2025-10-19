import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../app/data/models/user_model.dart';
import '../../../../app/data/providers/auth_provider.dart';
import '../../../../app/data/services/firebase_service.dart';
import '../../../../app/data/services/cloudinary_service.dart';
import '../../../../app/routes/app_routes.dart';

// Profile screen ka logic
class ProfileController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final ImagePicker _picker = ImagePicker();

  // Text Editing Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController farmSizeController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();

  // Reactive Variables
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final RxString selectedUserType = 'farmer'.obs;
  final RxString profileImagePath = ''.obs;
  final RxBool isUploadingImage = false.obs;

  // Current user ka data
  Rx<UserModel?> get user => _authProvider.currentUser;

  @override
  void onInit() {
    super.onInit();
    _initializeUserData();
  }

  // User data ko controllers mein fill karna
  void _initializeUserData() {
    final userData = user.value;
    if (userData != null) {
      nameController.text = userData.name;
      emailController.text = userData.email;
      phoneController.text = userData.phone;
      locationController.text = userData.location ?? '';
      farmSizeController.text = userData.farmSize ?? '';
      specializationController.text = userData.specialization ?? '';
      companyNameController.text = userData.companyName ?? '';
      selectedUserType.value = userData.userType;
      profileImagePath.value = userData.profileImage ?? '';
    }
  }

  // Edit mode toggle karna
  void toggleEditMode() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) {
      _initializeUserData(); // Discard changes
    }
  }

  // Profile image pick karna with Cloudinary upload
  Future<void> pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        isUploadingImage.value = true;

        // Upload to Cloudinary
        final imageUrl = await _cloudinaryService.uploadImage(
          File(image.path),
          folder: 'profile_images',
        );

        if (imageUrl != null) {
          profileImagePath.value = imageUrl;
          Get.snackbar('Success', 'Image uploaded successfully!');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick or upload image: $e');
    } finally {
      isUploadingImage.value = false;
    }
  }

  // Form validation
  bool validateForm() {
    if (nameController.text.isEmpty || nameController.text.length < 3) {
      Get.snackbar('Error', 'Please enter a valid name');
      return false;
    }
    if (emailController.text.isEmpty || !GetUtils.isEmail(emailController.text)) {
      Get.snackbar('Error', 'Please enter a valid email');
      return false;
    }
    if (phoneController.text.isEmpty || phoneController.text.length < 11) {
      Get.snackbar('Error', 'Please enter a valid phone number');
      return false;
    }
    return true;
  }

  // Profile update karna with Cloudinary image URL
  Future<void> updateProfile() async {
    if (!validateForm()) return;

    try {
      isLoading.value = true;

      final updatedUser = UserModel(
        uid: user.value!.uid,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        userType: selectedUserType.value,
        location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
        farmSize: farmSizeController.text.trim().isEmpty ? null : farmSizeController.text.trim(),
        specialization: specializationController.text.trim().isEmpty ? null : specializationController.text.trim(),
        companyName: companyNameController.text.trim().isEmpty ? null : companyNameController.text.trim(),
        profileImage: profileImagePath.value.isEmpty ? null : profileImagePath.value,
        createdAt: user.value!.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.saveUserData(updatedUser);

      // AuthProvider ko refresh karna taake updated data reflect ho
      await _authProvider.refreshUserData();

      isEditing.value = false;
      Get.snackbar('Success', 'Profile updated successfully!');

      // Navigate to home after profile completion
      Get.offAllNamed(AppRoutes.HOME);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Create Profile Later function
  void createProfileLater() {
    Get.defaultDialog(
      title: 'Skip Profile Creation',
      middleText: 'You can complete your profile later from the profile section.',
      textConfirm: 'Continue',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back(); // Close dialog
        Get.offAllNamed(AppRoutes.HOME); // Navigate to home
      },
    );
  }

  // User type change function
  void onUserTypeChanged(String? value) {
    if (value != null) {
      selectedUserType.value = value;
    }
  }

  // Account delete function (with confirmation)
  void deleteAccount() {
    Get.defaultDialog(
      title: 'Delete Account',
      titleStyle: TextStyle(color: Colors.red, fontSize: 18),
      middleText: 'Are you sure you want to delete your account? This action cannot be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        // TODO: Implement account deletion logic
        Get.snackbar('Info', 'Account deletion coming soon!');
      },
    );
  }

  @override
  void onClose() {
    // Controllers ko dispose karna
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    farmSizeController.dispose();
    specializationController.dispose();
    companyNameController.dispose();
    super.onClose();
  }
}