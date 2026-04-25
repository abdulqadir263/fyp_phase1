import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../app/data/models/user_model.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';
import '../repository/profile_repository.dart';

/// ProfileController (ViewModel) — manages Profile screen state and logic.
///
/// No direct Firebase/Cloudinary calls — all data ops go through ProfileRepository.
class ProfileController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final ProfileRepository _profileRepository = Get.find<ProfileRepository>();
  final ImagePicker _picker = ImagePicker();

  // --- Form controllers ---
// --- Form controllers --- (final hatao)
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController locationController;
  late TextEditingController farmSizeController;
  late TextEditingController specializationController;
  late TextEditingController companyNameController;

  // --- Reactive state ---
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final RxString userType = ''.obs;
  final RxString profileImageUrl = ''.obs;
  final RxBool isUploadingImage = false.obs;

  Rx<UserModel?> get user => _authRepository.currentUser;

  bool get isProfileIncomplete {
    final u = user.value;
    if (u == null) return false;
    switch (u.userType) {
      case 'farmer':
        return u.location == null || u.location!.isEmpty;
      case 'expert':
        return u.specialization == null || u.specialization!.isEmpty;
      case 'company':
        return u.companyName == null || u.companyName!.isEmpty;
      default:
        return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Controllers fresh initialize karo (agar pehle dispose ho chuke hon)
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    locationController = TextEditingController();
    farmSizeController = TextEditingController();
    specializationController = TextEditingController();
    companyNameController = TextEditingController();
    _populateFormFields();
  }

  void _populateFormFields() {
    final u = user.value;
    if (u == null) return;

    nameController.text = u.name;
    emailController.text = u.email;
    phoneController.text = u.phone;
    locationController.text = u.location ?? '';
    farmSizeController.text = u.farmSize ?? '';
    specializationController.text = u.specialization ?? '';
    companyNameController.text = u.companyName ?? '';
    userType.value = u.userType;
    profileImageUrl.value = u.profileImage ?? '';
  }

  void toggleEditMode() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) {
      _populateFormFields();
    }
  }

  /// Pick image and upload via repository
  Future<void> pickAndUploadImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked == null) return;

      isUploadingImage.value = true;

      final url = await _profileRepository.uploadProfileImage(
        File(picked.path),
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

  /// Save profile via repository
  Future<void> updateProfile() async {
    if (!_validateForm()) return;

    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;

    try {
      final current = user.value!;

      final updated = current.copyWith(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        location: locationController.text.trim().isEmpty
            ? null
            : locationController.text.trim(),
        farmSize: farmSizeController.text.trim().isEmpty
            ? null
            : farmSizeController.text.trim(),
        specialization: specializationController.text.trim().isEmpty
            ? null
            : specializationController.text.trim(),
        companyName: companyNameController.text.trim().isEmpty
            ? null
            : companyNameController.text.trim(),
        profileImage: profileImageUrl.value.isEmpty
            ? null
            : profileImageUrl.value,
        updatedAt: DateTime.now(),
      );

      // Persist via repository
      await _profileRepository.saveProfile(updated);

      // Update in-memory state
      _authRepository.currentUser.value = updated;

      isEditing.value = false;
      AppSnackbar.success('Profile updated!');
      Get.back();
    } catch (e) {
      if (kDebugMode) debugPrint('ProfileController: updateProfile error → $e');
      AppSnackbar.error('Failed to update profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void skipProfileSetup() {
    Get.defaultDialog(
      title: 'Skip for Now',
      middleText:
          'You can complete your profile later from the profile section.',
      textConfirm: 'Continue',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        Get.offAllNamed(AppRoutes.HOME);
      },
    );
  }

  void changeUserType(String? value) {
    if (value != null) userType.value = value;
  }

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
