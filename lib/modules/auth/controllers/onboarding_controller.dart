import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/data/services/firebase_service.dart';
import '../../../app/utils/app_snackbar.dart';
import 'auth_controller.dart';

/// OnboardingController — ViewModel for the Role Selection and Profile Completion screens.
///
/// Handles the one-time onboarding flow:
/// 1. User picks a role (Farmer / Expert / Company)
/// 2. Fills role-specific profile fields
/// 3. Profile saved to Firestore → navigated to Home
class OnboardingController extends GetxController {
  final AuthProvider    _authProvider    = Get.find<AuthProvider>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController  _authController  = Get.find<AuthController>();

  // --- Role selection ---
  final RxString selectedRole = ''.obs;
  final RxBool   isLoading    = false.obs;

  // --- Common profile fields ---
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController locationController;

  // --- Farmer-specific ---
  late final TextEditingController farmSizeController;
  final RxList<String> selectedCrops = <String>[].obs;

  static const List<String> availableCrops = [
    'Wheat', 'Rice', 'Potatoes', 'Maize',
    'Cotton', 'Sugarcane', 'Canola',
  ];

  // --- Expert-specific ---
  final RxString selectedSpecialization       = ''.obs;
  late final TextEditingController yearsExperienceController;
  late final TextEditingController certificationsController;
  late final TextEditingController bioController;
  final RxBool isAvailableForConsultation = true.obs;

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

  // --- Company/Seller-specific ---
  late final TextEditingController companyNameController;
  late final TextEditingController ownerNameController;
  final RxString selectedBusinessType  = ''.obs;
  late final TextEditingController yearsInBusinessController;
  late final TextEditingController licenseNumberController;
  late final TextEditingController businessDescriptionController;

  static const List<String> businessTypes = [
    'Seeds Supplier',
    'Fertilizer Dealer',
    'Pesticide Dealer',
    'Agricultural Equipment',
    'Crop Buyer',
    'Livestock Trader',
    'General Agri Store',
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // COMPUTED GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  /// True when the current user signed in anonymously (guest farmer flow).
  /// Used by ProfileCompletionView to hide the "Skip" button.
  bool get isAnonymousFarmer =>
      (_authProvider.currentUser.value?.isAnonymous ?? false) &&
      selectedRole.value == 'farmer';

  // ─────────────────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    nameController = TextEditingController();
    phoneController = TextEditingController();
    locationController = TextEditingController();
    farmSizeController = TextEditingController();
    yearsExperienceController = TextEditingController();
    certificationsController = TextEditingController();
    bioController = TextEditingController();
    companyNameController = TextEditingController();
    ownerNameController = TextEditingController();
    yearsInBusinessController = TextEditingController();
    licenseNumberController = TextEditingController();
    businessDescriptionController = TextEditingController();

    _prefillFromCurrentUser();
  }

  /// Pre-fill fields with any existing user data (returning user or signup carry-over).
  void _prefillFromCurrentUser() {
    final user = _authProvider.currentUser.value;
    if (user == null) return;

    nameController.text     = user.name;
    phoneController.text    = user.phone;
    locationController.text = user.location ?? '';

    if (user.userType.isNotEmpty) {
      selectedRole.value = user.userType;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ROLE SELECTION
  // ─────────────────────────────────────────────────────────────────────────

  /// User tapped a role card.
  /// Navigation is centralized in AuthController.
  Future<void> selectRole(String role) async {
    if (isLoading.value) return;

    selectedRole.value = role;
    await _authController.handleRoleSelection(role);
  }

  void goBackToRoleSelection() => _authController.openRoleSelection();

  // ─────────────────────────────────────────────────────────────────────────
  // CROP SELECTION (Farmers only)
  // ─────────────────────────────────────────────────────────────────────────

  void toggleCropSelection(String crop) {
    if (selectedCrops.contains(crop)) {
      selectedCrops.remove(crop);
    } else {
      selectedCrops.add(crop);
    }
  }

  bool isCropSelected(String crop) => selectedCrops.contains(crop);

  // ─────────────────────────────────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Shared check — name must be at least 3 characters.
  bool _validateName() {
    if (nameController.text.trim().length < 3) {
      AppSnackbar.error('Please enter your name (at least 3 characters)');
      return false;
    }
    return true;
  }

  /// Farmer profile: name + phone + location are required. Crops required too.
  bool _validateFarmerProfile() {
    if (!_validateName()) return false;
    if (phoneController.text.trim().length < 11) {
      AppSnackbar.error('Please enter a valid phone number');
      return false;
    }
    if (locationController.text.trim().isEmpty) {
      AppSnackbar.error('Please enter your farm location');
      return false;
    }
    if (selectedCrops.isEmpty) {
      AppSnackbar.error('Please select at least one crop');
      return false;
    }
    return true;
  }

  /// Expert profile: name + specialization + years of experience required.
  bool _validateExpertProfile() {
    if (!_validateName()) return false;
    if (selectedSpecialization.value.isEmpty) {
      AppSnackbar.error('Please select your specialization');
      return false;
    }
    final years = int.tryParse(yearsExperienceController.text.trim());
    if (years == null || years < 0) {
      AppSnackbar.error('Please enter a valid number for years of experience');
      return false;
    }
    return true;
  }

  /// Company profile: company name + business type required.
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

  /// Dispatches to the correct role validator.
  bool validateProfile() {
    switch (selectedRole.value) {
      case 'farmer':  return _validateFarmerProfile();
      case 'expert':  return _validateExpertProfile();
      case 'company': return _validateCompanyProfile();
      default:
        AppSnackbar.error('Please select a role first');
        return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SAVE PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  /// Validate, build the updated UserModel, save to Firestore, navigate home.
  Future<void> saveProfile() async {
    if (!validateProfile()) return;

    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;

    try {
      final current = _authProvider.currentUser.value;
      if (current == null) {
        AppSnackbar.error('Session expired. Please login again.');
        return;
      }

      // Pre-trim once — avoids repeating .trim() throughout the switch
      final name     = nameController.text.trim();
      final phone    = phoneController.text.trim();
      final location = locationController.text.trim();

      UserModel updated;

      switch (selectedRole.value) {
        case 'farmer':
          updated = current.copyWith(
            name:             name,
            phone:            phone,
            userType:         'farmer',
            location:         location,
            farmSize:         farmSizeController.text.trim().isEmpty ? null : farmSizeController.text.trim(),
            cropsGrown:       selectedCrops.toList(),
            isProfileComplete: true,
            updatedAt:        DateTime.now(),
          );
          break;

        case 'expert':
          updated = current.copyWith(
            name:             name,
            phone:            phone,
            userType:         'expert',
            location:         location.isEmpty ? null : location,
            specialization:   selectedSpecialization.value,
            yearsOfExperience: int.tryParse(yearsExperienceController.text.trim()),
            certifications:   certificationsController.text.trim().isEmpty ? null : certificationsController.text.trim(),
            bio:              bioController.text.trim().isEmpty ? null : bioController.text.trim(),
            isAvailableForConsultation: isAvailableForConsultation.value,
            isProfileComplete: true,
            updatedAt:        DateTime.now(),
          );
          break;

        case 'company':
          final ownerName = ownerNameController.text.trim();
          updated = current.copyWith(
            name:                ownerName.isEmpty ? name : ownerName,
            phone:               phone,
            userType:            'company',
            location:            location.isEmpty ? null : location,
            companyName:         companyNameController.text.trim(),
            businessType:        selectedBusinessType.value,
            yearsInBusiness:     int.tryParse(yearsInBusinessController.text.trim()),
            licenseNumber:       licenseNumberController.text.trim().isEmpty ? null : licenseNumberController.text.trim(),
            businessDescription: businessDescriptionController.text.trim().isEmpty ? null : businessDescriptionController.text.trim(),
            isProfileComplete:   true,
            updatedAt:           DateTime.now(),
          );
          break;

        default:
          AppSnackbar.error('Invalid role selected');
          return;
      }

      // Persist to Firestore
      await _firebaseService.saveUserData(updated);

      // Update in-memory state — no Firestore round-trip needed
      _authProvider.currentUser.value = updated;

      AppSnackbar.success('Profile saved!');
    } catch (e) {
      if (kDebugMode) debugPrint('OnboardingController: saveProfile error → $e');
      AppSnackbar.error('Failed to save profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLEANUP
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void onClose() {
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
