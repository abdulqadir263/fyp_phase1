import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/data/models/user_model.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';
import '../repository/profile_repository.dart';

class ProfileController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final ProfileRepository _profileRepository = Get.find<ProfileRepository>();
  final ImagePicker _picker = ImagePicker();

  // ── Common fields ──────────────────────────────────────────────────────────
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  // ── Farmer fields ──────────────────────────────────────────────────────────
  late TextEditingController locationController;
  late TextEditingController farmSizeController;
  final RxList<String> selectedCrops = <String>[].obs;

  // ── Expert fields ──────────────────────────────────────────────────────────
  final RxString selectedSpecialization = ''.obs;
  late TextEditingController yearsOfExperienceController;
  late TextEditingController certificationsController;
  late TextEditingController bioController;
  late TextEditingController consultationFeeController;
  final RxBool isAvailableForConsultation = false.obs;
  final RxList<String> selectedDays = <String>[].obs;
  final RxList<String> selectedSlots = <String>[].obs;
  final RxString consultationMode = 'Both'.obs;

  // ── Company fields ─────────────────────────────────────────────────────────
  late TextEditingController companyNameController;
  final RxString selectedBusinessType = ''.obs;
  late TextEditingController yearsInBusinessController;
  late TextEditingController licenseNumberController;
  late TextEditingController businessDescriptionController;

  // ── UI state ───────────────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final RxString userType = ''.obs;
  final RxString profileImageUrl = ''.obs;
  final RxBool isUploadingImage = false.obs;
  final RxString displayName = ''.obs;

  // ── Constants ──────────────────────────────────────────────────────────────
  static const crops = [
    'Wheat', 'Rice', 'Potatoes', 'Maize',
    'Cotton', 'Sugarcane', 'Canola',
  ];

  static const specializations = [
    'Crop Management', 'Pest & Disease Control', 'Soil Science',
    'Irrigation Systems', 'Livestock Management', 'Agricultural Machinery',
    'Agri Business & Marketing', 'Organic Farming',
    'Fertilizer & Nutrient Management',
  ];

  static const weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  static const timeSlots = [
    '8:00 AM – 11:00 AM',
    '11:00 AM – 2:00 PM',
    '2:00 PM – 5:00 PM',
    '5:00 PM – 8:00 PM',
  ];

  static const consultationModes = ['In-Person', 'Online', 'Both'];

  static const businessTypes = [
    'Seeds & Fertilizers', 'Pesticides & Chemicals', 'Farm Equipment',
    'Dairy Products', 'Livestock', 'Organic Products', 'Other',
  ];

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
    yearsOfExperienceController = TextEditingController();
    certificationsController = TextEditingController();
    bioController = TextEditingController();
    consultationFeeController = TextEditingController();
    companyNameController = TextEditingController();
    yearsInBusinessController = TextEditingController();
    licenseNumberController = TextEditingController();
    businessDescriptionController = TextEditingController();

    nameController.addListener(() => displayName.value = nameController.text);
    _populateFormFields();
  }

  void _populateFormFields() {
    final u = user.value;
    if (u == null) return;

    // Common
    nameController.text = u.name;
    emailController.text = u.email;
    phoneController.text = u.phone;
    userType.value = u.userType;
    profileImageUrl.value = u.profileImage ?? '';
    displayName.value = u.name;

    // Farmer
    locationController.text = u.location ?? '';
    farmSizeController.text = u.farmSize ?? '';
    selectedCrops.assignAll(u.cropsGrown ?? []);

    // Expert
    selectedSpecialization.value = u.specialization ?? '';
    yearsOfExperienceController.text =
        u.yearsOfExperience != null ? '${u.yearsOfExperience}' : '';
    certificationsController.text = u.certifications ?? '';
    bioController.text = u.bio ?? '';
    consultationFeeController.text =
        u.consultationFee != null ? '${u.consultationFee}' : '';
    isAvailableForConsultation.value = u.isAvailableForConsultation ?? false;
    selectedDays.assignAll(u.availableDays ?? []);
    selectedSlots.assignAll(u.availableSlots ?? []);
    consultationMode.value =
        (u.consultationMode?.isNotEmpty == true) ? u.consultationMode! : 'Both';

    // Company
    companyNameController.text = u.companyName ?? '';
    selectedBusinessType.value = u.businessType ?? '';
    yearsInBusinessController.text =
        u.yearsInBusiness != null ? '${u.yearsInBusiness}' : '';
    licenseNumberController.text = u.licenseNumber ?? '';
    businessDescriptionController.text = u.businessDescription ?? '';
  }

  @override
  void onReady() {
    super.onReady();
    isEditing.value = false;
    _populateFormFields();
  }

  void toggleEditMode() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) _populateFormFields();
  }

  void toggleCrop(String crop) {
    if (selectedCrops.contains(crop)) {
      selectedCrops.remove(crop);
    } else {
      selectedCrops.add(crop);
    }
  }

  void toggleDay(String day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
  }

  void toggleSlot(String slot) {
    if (selectedSlots.contains(slot)) {
      selectedSlots.remove(slot);
    } else {
      selectedSlots.add(slot);
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      isUploadingImage.value = true;
      final url = await _profileRepository.uploadProfileImage(picked);
      if (url != null) {
        profileImageUrl.value = url;
        final updated =
            user.value!.copyWith(profileImage: url, updatedAt: DateTime.now());
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
    if (nameController.text.trim().length < 3) {
      AppSnackbar.error('Please enter a valid name (at least 3 characters)');
      return false;
    }
    if (phoneController.text.trim().length < 11) {
      AppSnackbar.error('Please enter a valid 11-digit phone number');
      return false;
    }
    return true;
  }

  Future<void> updateProfile() async {
    if (!_validateForm()) return;

    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;

    try {
      final current = user.value!;

      // Build UserModel directly — avoids copyWith null-clearing issue
      final updated = UserModel(
        uid: current.uid,
        email: current.email,
        createdAt: current.createdAt,
        isAnonymous: current.isAnonymous,
        updatedAt: DateTime.now(),
        isProfileComplete: true,
        // Common editable
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        userType: current.userType,
        profileImage: profileImageUrl.value.isNotEmpty
            ? profileImageUrl.value
            : current.profileImage,
        // Farmer
        location: locationController.text.trim().isNotEmpty
            ? locationController.text.trim()
            : null,
        farmSize: farmSizeController.text.trim().isNotEmpty
            ? farmSizeController.text.trim()
            : null,
        cropsGrown:
            selectedCrops.isNotEmpty ? List<String>.from(selectedCrops) : null,
        // Expert
        specialization: selectedSpecialization.value.isNotEmpty
            ? selectedSpecialization.value
            : null,
        yearsOfExperience:
            int.tryParse(yearsOfExperienceController.text.trim()),
        certifications: certificationsController.text.trim().isNotEmpty
            ? certificationsController.text.trim()
            : null,
        bio: bioController.text.trim().isNotEmpty
            ? bioController.text.trim()
            : null,
        isAvailableForConsultation: isAvailableForConsultation.value,
        availableDays:
            selectedDays.isNotEmpty ? List<String>.from(selectedDays) : null,
        availableSlots:
            selectedSlots.isNotEmpty ? List<String>.from(selectedSlots) : null,
        consultationFee:
            int.tryParse(consultationFeeController.text.trim()) ?? 0,
        consultationMode: consultationMode.value,
        // Company
        companyName: companyNameController.text.trim().isNotEmpty
            ? companyNameController.text.trim()
            : null,
        businessType: selectedBusinessType.value.isNotEmpty
            ? selectedBusinessType.value
            : null,
        yearsInBusiness:
            int.tryParse(yearsInBusinessController.text.trim()),
        licenseNumber: licenseNumberController.text.trim().isNotEmpty
            ? licenseNumberController.text.trim()
            : null,
        businessDescription: businessDescriptionController.text.trim().isNotEmpty
            ? businessDescriptionController.text.trim()
            : null,
      );

      await _profileRepository.saveProfile(updated);
      _authRepository.currentUser.value = updated;

      isEditing.value = false;
      Future.delayed(const Duration(milliseconds: 300), () {
        AppSnackbar.success('Profile updated successfully!');
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
    yearsOfExperienceController.dispose();
    certificationsController.dispose();
    bioController.dispose();
    consultationFeeController.dispose();
    companyNameController.dispose();
    yearsInBusinessController.dispose();
    licenseNumberController.dispose();
    businessDescriptionController.dispose();
    super.onClose();
  }
}
