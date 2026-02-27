import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/data/services/firebase_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';

/// OnboardingController - Manages the role selection and profile completion flow
/// Handles different profile fields based on user role (Farmer, Expert, Company)
class OnboardingController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  // ========== ROLE SELECTION STATE ==========
  final RxString selectedRole = ''.obs;
  final RxBool isLoading = false.obs;

  // ========== COMMON PROFILE FIELDS ==========
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // ========== FARMER-SPECIFIC FIELDS ==========
  final TextEditingController farmSizeController = TextEditingController();
  final RxList<String> selectedCrops = <String>[].obs;

  /// Available crops for multi-selection (farmer-friendly names)
  static const List<String> availableCrops = [
    'Wheat',
    'Rice',
    'Potatoes',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Canola',
  ];

  // ========== EXPERT-SPECIFIC FIELDS ==========
  final RxString selectedSpecialization = ''.obs;
  final TextEditingController yearsExperienceController = TextEditingController();
  final TextEditingController certificationsController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final RxBool isAvailableForConsultation = true.obs;

  /// Available specializations for experts
  static const List<String> expertSpecializations = [
    'Crop Management',
    'Pest & Disease Control',
    'Soil Science',
    'Irrigation Systems',
    'Livestock Management',
    'Agricultural Machinery',
    'Agri Business & Marketing',
    'Organic Farming',
    'Fertilizer & Nutrient Management',
  ];

  // ========== COMPANY/SELLER-SPECIFIC FIELDS ==========
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final RxString selectedBusinessType = ''.obs;
  final TextEditingController yearsInBusinessController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController businessDescriptionController = TextEditingController();

  /// Available business types for company/seller
  static const List<String> businessTypes = [
    'Seeds Supplier',
    'Fertilizer Dealer',
    'Pesticide Dealer',
    'Agricultural Equipment',
    'Crop Buyer',
    'Livestock Trader',
    'General Agri Store',
  ];

  @override
  void onInit() {
    super.onInit();
    _initializeFromCurrentUser();
  }

  /// Initialize fields from current user data if available
  void _initializeFromCurrentUser() {
    final user = _authProvider.currentUser.value;
    if (user != null) {
      nameController.text = user.name;
      phoneController.text = user.phone;
      locationController.text = user.location ?? '';
      // Only set role if user already has a userType (returning user)
      if (user.userType.isNotEmpty) {
        selectedRole.value = user.userType;
      }
    }
  }

  // ========== ROLE SELECTION METHODS ==========

  /// Select a role and navigate to profile completion
  void selectRole(String role) {
    selectedRole.value = role;
    debugPrint('OnboardingController: Role selected - $role');
    Get.toNamed(AppRoutes.PROFILE_COMPLETION);
  }

  /// Continue as guest - no Firestore profile created
  void continueAsGuest() {
    debugPrint('OnboardingController: Continuing as guest');
    _authProvider.signInAsGuest();
  }

  // ========== FARMER CROP SELECTION METHODS ==========

  /// Toggle crop selection
  void toggleCropSelection(String crop) {
    if (selectedCrops.contains(crop)) {
      selectedCrops.remove(crop);
    } else {
      selectedCrops.add(crop);
    }
  }

  /// Check if a crop is selected
  bool isCropSelected(String crop) {
    return selectedCrops.contains(crop);
  }

  // ========== VALIDATION METHODS ==========

  /// Validate farmer profile fields
  bool _validateFarmerProfile() {
    if (nameController.text.trim().isEmpty) {
      AppSnackbar.error('Please enter your name');
      return false;
    }
    if (locationController.text.trim().isEmpty) {
      AppSnackbar.error('Please enter your location');
      return false;
    }
    if (selectedCrops.isEmpty) {
      AppSnackbar.error('Please select at least one crop');
      return false;
    }
    return true;
  }

  /// Validate expert profile fields
  bool _validateExpertProfile() {
    if (nameController.text.trim().isEmpty) {
      AppSnackbar.error('Please enter your name');
      return false;
    }
    if (selectedSpecialization.value.isEmpty) {
      AppSnackbar.error('Please select your specialization');
      return false;
    }
    if (yearsExperienceController.text.trim().isEmpty) {
      AppSnackbar.error('Please enter your years of experience');
      return false;
    }
    final years = int.tryParse(yearsExperienceController.text.trim());
    if (years == null || years < 0) {
      AppSnackbar.error('Please enter a valid number for experience');
      return false;
    }
    return true;
  }

  /// Validate company profile fields
  bool _validateCompanyProfile() {
    if (companyNameController.text.trim().isEmpty) {
      AppSnackbar.error('Please enter your company name');
      return false;
    }
    if (selectedBusinessType.value.isEmpty) {
      AppSnackbar.error('Please select your business type');
      return false;
    }
    return true;
  }

  /// Main validation method based on selected role
  bool validateProfile() {
    switch (selectedRole.value) {
      case 'farmer':
        return _validateFarmerProfile();
      case 'expert':
        return _validateExpertProfile();
      case 'company':
        return _validateCompanyProfile();
      default:
        AppSnackbar.error('Please select a role first');
        return false;
    }
  }

  // ========== PROFILE SAVE METHODS ==========

  /// Save completed profile to Firestore
  Future<void> saveProfile() async {
    if (!validateProfile()) return;

    // Dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      isLoading.value = true;

      final currentUser = _authProvider.currentUser.value;
      if (currentUser == null) {
        AppSnackbar.error('User session expired. Please login again.');
        Get.offAllNamed(AppRoutes.LOGIN);
        return;
      }

      // Build updated user model based on role
      UserModel updatedUser;

      switch (selectedRole.value) {
        case 'farmer':
          updatedUser = currentUser.copyWith(
            name: nameController.text.trim(),
            phone: phoneController.text.trim(),
            userType: 'farmer',
            location: locationController.text.trim(),
            farmSize: farmSizeController.text.trim().isEmpty
                ? null
                : farmSizeController.text.trim(),
            cropsGrown: selectedCrops.toList(),
            isProfileComplete: true,
            updatedAt: DateTime.now(),
          );
          break;

        case 'expert':
          updatedUser = currentUser.copyWith(
            name: nameController.text.trim(),
            phone: phoneController.text.trim(),
            userType: 'expert',
            location: locationController.text.trim().isEmpty
                ? null
                : locationController.text.trim(),
            specialization: selectedSpecialization.value,
            yearsOfExperience: int.tryParse(yearsExperienceController.text.trim()),
            certifications: certificationsController.text.trim().isEmpty
                ? null
                : certificationsController.text.trim(),
            bio: bioController.text.trim().isEmpty
                ? null
                : bioController.text.trim(),
            isAvailableForConsultation: isAvailableForConsultation.value,
            isProfileComplete: true,
            updatedAt: DateTime.now(),
          );
          break;

        case 'company':
          updatedUser = currentUser.copyWith(
            name: ownerNameController.text.trim().isEmpty
                ? nameController.text.trim()
                : ownerNameController.text.trim(),
            phone: phoneController.text.trim(),
            userType: 'company',
            location: locationController.text.trim().isEmpty
                ? null
                : locationController.text.trim(),
            companyName: companyNameController.text.trim(),
            businessType: selectedBusinessType.value,
            yearsInBusiness: int.tryParse(yearsInBusinessController.text.trim()),
            licenseNumber: licenseNumberController.text.trim().isEmpty
                ? null
                : licenseNumberController.text.trim(),
            businessDescription: businessDescriptionController.text.trim().isEmpty
                ? null
                : businessDescriptionController.text.trim(),
            isProfileComplete: true,
            updatedAt: DateTime.now(),
          );
          break;

        default:
          AppSnackbar.error('Invalid role selected');
          return;
      }

      // Save to Firestore (creates doc if it doesn't exist, merges if it does)
      await _firebaseService.saveUserData(updatedUser);

      // Update the auth provider's current user in memory
      _authProvider.currentUser.value = updatedUser;

      AppSnackbar.success('Profile saved successfully!');

      // Navigate to home
      Get.offAllNamed(AppRoutes.HOME);

    } catch (e) {
      debugPrint('OnboardingController: Error saving profile - $e');
      AppSnackbar.error('Failed to save profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Go back to role selection
  void goBackToRoleSelection() {
    Get.back();
  }

  @override
  void onClose() {
    // Dispose all controllers
    nameController.dispose();
    phoneController.dispose();
    locationController.dispose();
    farmSizeController.dispose();
    yearsExperienceController.dispose();
    certificationsController.dispose();
    bioController.dispose();
    companyNameController.dispose();
    ownerNameController.dispose();
    yearsInBusinessController.dispose();
    licenseNumberController.dispose();
    businessDescriptionController.dispose();
    super.onClose();
  }
}

