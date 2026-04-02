import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../app/data/models/user_model.dart';
import '../../../../app/data/providers/auth_provider.dart';
import '../../../../app/data/services/firebase_service.dart';
import '../../../../app/data/services/cloudinary_service.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/utils/app_snackbar.dart';

/// ProfileController — ViewModel for the Profile screen.
///
/// Supports viewing and editing profiles for Farmer, Expert, and Company users.
class ProfileController extends GetxController {
  final AuthProvider      _authProvider      = Get.find<AuthProvider>();
  final FirebaseService   _firebaseService   = Get.find<FirebaseService>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final ImagePicker       _picker            = ImagePicker();

  // --- Form controllers ---
  final nameController          = TextEditingController();
  final emailController         = TextEditingController();
  final phoneController         = TextEditingController();
  final locationController      = TextEditingController();
  final farmSizeController      = TextEditingController();
  final specializationController = TextEditingController();
  final companyNameController   = TextEditingController();

  // --- Reactive state ---
  final RxBool   isLoading        = false.obs;
  final RxBool   isEditing        = false.obs;
  final RxString userType         = ''.obs;     // reflects actual user role
  final RxString profileImageUrl  = ''.obs;     // Cloudinary CDN URL (not a local path)
  final RxBool   isUploadingImage = false.obs;

  /// Shortcut to the current user — shared with the rest of the app.
  Rx<UserModel?> get user => _authProvider.currentUser;

  /// True when the user's profile is missing required role-specific fields.
  /// Used to decide whether to show the "Skip setup" button.
  bool get isProfileIncomplete {
    final u = user.value;
    if (u == null) return false;
    switch (u.userType) {
      case 'farmer':  return u.location == null || u.location!.isEmpty;
      case 'expert':  return u.specialization == null || u.specialization!.isEmpty;
      case 'company': return u.companyName == null || u.companyName!.isEmpty;
      default:        return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _populateFormFields();
  }

  /// Fill text controllers from current user data.
  /// Called on init and when cancelling an edit (to discard unsaved changes).
  void _populateFormFields() {
    final u = user.value;
    if (u == null) return;

    nameController.text           = u.name;
    emailController.text          = u.email;
    phoneController.text          = u.phone;
    locationController.text       = u.location ?? '';
    farmSizeController.text       = u.farmSize ?? '';
    specializationController.text = u.specialization ?? '';
    companyNameController.text    = u.companyName ?? '';
    userType.value                = u.userType;
    profileImageUrl.value         = u.profileImage ?? '';
  }

  /// Toggle between view and edit modes.
  /// Cancelling edit mode restores all form fields to the last saved values.
  void toggleEditMode() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) {
      _populateFormFields(); // discard unsaved changes
    }
  }

  /// Open the gallery, upload the chosen image to Cloudinary, and update the URL.
  Future<void> pickAndUploadImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return; // user cancelled

      isUploadingImage.value = true;

      final url = await _cloudinaryService.uploadImage(
        File(picked.path),
        folder: 'profile_images',
      );

      if (url != null) {
        profileImageUrl.value = url;
        AppSnackbar.success('Profile photo updated!');
      }
    } catch (e) {
      AppSnackbar.error('Failed to upload image. Please try again.');
      if (kDebugMode) debugPrint('ProfileController: Image upload error → $e');
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// Validates name, email, and phone.
  bool _validateForm() {
    if (nameController.text.trim().length < 3) {
      AppSnackbar.error('Please enter a valid name (at least 3 characters)');
      return false;
    }
    if (!GetUtils.isEmail(emailController.text.trim())) {
      AppSnackbar.error('Please enter a valid email');
      return false;
    }
    if (phoneController.text.trim().length < 11) {
      AppSnackbar.error('Please enter a valid phone number');
      return false;
    }
    return true;
  }

  /// Save the edited profile to Firestore.
  ///
  /// Uses copyWith() to preserve all existing fields (cropsGrown, certifications,
  /// yearsOfExperience, etc.) that are not shown on this screen.
  /// Avoids the data loss bug of constructing a new UserModel from scratch.
  Future<void> updateProfile() async {
    if (!_validateForm()) return;

    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;

    try {
      final current = user.value!;

      // Build updated user — copyWith keeps every field not explicitly overridden
      final updated = current.copyWith(
        name:          nameController.text.trim(),
        phone:         phoneController.text.trim(),
        location:      locationController.text.trim().isEmpty ? null : locationController.text.trim(),
        farmSize:      farmSizeController.text.trim().isEmpty ? null : farmSizeController.text.trim(),
        specialization: specializationController.text.trim().isEmpty ? null : specializationController.text.trim(),
        companyName:   companyNameController.text.trim().isEmpty ? null : companyNameController.text.trim(),
        profileImage:  profileImageUrl.value.isEmpty ? null : profileImageUrl.value,
        updatedAt:     DateTime.now(),
      );

      // Persist to Firestore
      await _firebaseService.saveUserData(updated);

      // Update in-memory state directly — avoids an extra Firestore read
      _authProvider.currentUser.value = updated;

      isEditing.value = false;
      AppSnackbar.success('Profile updated!');

      // Go back to the previous screen (home nav bar) — not offAllNamed
      Get.back();
    } catch (e) {
      if (kDebugMode) debugPrint('ProfileController: updateProfile error → $e');
      AppSnackbar.error('Failed to update profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Show dialog letting the user skip profile setup for now.
  void skipProfileSetup() {
    Get.defaultDialog(
      title: 'Skip for Now',
      middleText: 'You can complete your profile later from the profile section.',
      textConfirm: 'Continue',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        Get.offAllNamed(AppRoutes.HOME);
      },
    );
  }

  /// Update selected user type from the dropdown (visible in edit mode only).
  void changeUserType(String? value) {
    if (value != null) userType.value = value;
  }

  /// Show account deletion confirmation dialog.
  void deleteAccount() {
    Get.defaultDialog(
      title: 'Delete Account',
      titleStyle: const TextStyle(color: Colors.red, fontSize: 18),
      middleText: 'Are you sure? This action cannot be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        // TODO: Implement account deletion — Phase 2
        AppSnackbar.info('Account deletion coming soon.');
      },
    );
  }

  @override
  void onClose() {
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