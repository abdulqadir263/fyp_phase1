import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
// dart:io removed — File not supported on Flutter Web
import '../../../app/data/models/user_model.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';
import '../repository/profile_repository.dart';

class ProfileController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final ProfileRepository _profileRepository = Get.find<ProfileRepository>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController locationController;
  late TextEditingController farmSizeController;
  late TextEditingController specializationController;
  late TextEditingController companyNameController;

  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final RxString userType = ''.obs;
  final RxString profileImageUrl = ''.obs;
  final RxBool isUploadingImage = false.obs;

  // Reactive name — used in Obx header instead of nameController.text
  // TextEditingController is NOT observable, so this bridges the gap
  final RxString displayName = ''.obs;

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
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    locationController = TextEditingController();
    farmSizeController = TextEditingController();
    specializationController = TextEditingController();
    companyNameController = TextEditingController();

    // Keep displayName in sync with nameController while editing
    nameController.addListener(() {
      displayName.value = nameController.text;
    });

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
    displayName.value = u.name; // sync on populate
  }

  @override
  void onReady() {
    super.onReady();
    // Reset editing state — agar pehle edit mode mein navigate kar gaye the
    isEditing.value = false;
    _populateFormFields();
  }

  void toggleEditMode() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) _populateFormFields();
  }

  Future<void> pickAndUploadImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      isUploadingImage.value = true;
      // XFile passed directly — no File() wrapping needed (web compatible)
      final url = await _profileRepository.uploadProfileImage(picked);
      if (url != null) {
        profileImageUrl.value = url;

        // Persist to Firestore immediately so the URL isn't lost
        final updated = user.value!.copyWith(
          profileImage: url,
          updatedAt: DateTime.now(),
        );
        await _profileRepository.saveProfile(updated);
        _authRepository.currentUser.value = updated;

        AppSnackbar.success('Profile photo updated!');
      }
    } catch (e) {
      AppSnackbar.error('Failed to upload image. Please try again.');
      if (kDebugMode) debugPrint('ProfileController: image upload error → $e');
    } finally {
      isUploadingImage.value = false;
    }
  }

  bool _validateForm() {
    debugPrint('🔍 Validating — name: "${nameController.text.trim()}" length: ${nameController.text.trim().length}');

    if (nameController.text.trim().length < 3) {
      debugPrint(' Name too short');
      AppSnackbar.error('Please enter a valid name (at least 3 characters)');
      return false;
    }

    debugPrint('🔍 Phone: "${phoneController.text.trim()}" length: ${phoneController.text.trim().length}');
    if (phoneController.text.trim().length < 11) {
      debugPrint(' Phone too short');
      AppSnackbar.error('Please enter a valid phone number');
      return false;
    }

    debugPrint('✅ Validation passed');
    return true;
  }

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
            ? null : locationController.text.trim(),
        farmSize: farmSizeController.text.trim().isEmpty
            ? null : farmSizeController.text.trim(),
        specialization: specializationController.text.trim().isEmpty
            ? null : specializationController.text.trim(),
        companyName: companyNameController.text.trim().isEmpty
            ? null : companyNameController.text.trim(),
        profileImage: profileImageUrl.value.isEmpty
            ? null : profileImageUrl.value,
        updatedAt: DateTime.now(),
      );

      await _profileRepository.saveProfile(updated);
      _authRepository.currentUser.value = updated;

      isEditing.value = false;
      // Delay — isEditing false hone ke baad overlay settle hoti hai
      Future.delayed(const Duration(milliseconds: 300), () {
        AppSnackbar.success('Profile updated!');
      });
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