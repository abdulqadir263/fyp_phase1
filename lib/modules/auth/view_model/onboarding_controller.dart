import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/data/models/user_model.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/data/services/firebase_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';
import 'auth_controller.dart';

class OnboardingController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();

  // Used to trigger field-level validation (red borders + error text)
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxString selectedRole = ''.obs;
  final RxBool isLoading = false.obs;

  // Enables real-time validation after first save attempt
  final RxBool autoValidate = false.obs;

  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController locationController;
  late final TextEditingController farmSizeController;
  final RxList<String> selectedCrops = <String>[].obs;

  static const List<String> availableCrops = [
    'Wheat', 'Rice', 'Potatoes', 'Maize',
    'Cotton', 'Sugarcane', 'Canola',
  ];

  final RxString selectedSpecialization = ''.obs;
  late final TextEditingController yearsExperienceController;
  late final TextEditingController certificationsController;
  late final TextEditingController bioController;
  final RxBool isAvailableForConsultation = true.obs;

  static const List<String> expertSpecializations = [
    'Crop Management', 'Pest & Disease Control', 'Soil Science',
    'Irrigation Systems', 'Livestock Management', 'Agricultural Machinery',
    'Agri Business & Marketing', 'Organic Farming',
    'Fertilizer & Nutrient Management',
  ];

  late final TextEditingController companyNameController;
  late final TextEditingController ownerNameController;
  final RxString selectedBusinessType = ''.obs;
  late final TextEditingController yearsInBusinessController;
  late final TextEditingController licenseNumberController;
  late final TextEditingController businessDescriptionController;

  static const List<String> businessTypes = [
    'Seeds Supplier', 'Fertilizer Dealer', 'Pesticide Dealer',
    'Agricultural Equipment', 'Crop Buyer', 'Livestock Trader',
    'General Agri Store',
  ];

  bool get isAnonymousFarmer =>
      (_authRepository.currentUser.value?.isAnonymous ?? false) &&
          selectedRole.value == 'farmer';

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

  void _prefillFromCurrentUser() {
    final user = _authRepository.currentUser.value;
    if (user == null) return;
    nameController.text = user.name;
    phoneController.text = user.phone;
    locationController.text = user.location ?? '';
    if (user.userType.isNotEmpty) selectedRole.value = user.userType;
  }

  Future<void> selectRole(String role) async {
    if (isLoading.value) return;
    selectedRole.value = role;
    autoValidate.value = false;
    await _authController.handleRoleSelection(role);
  }

  void goBackToRoleSelection() => _authController.openRoleSelection();

  void toggleCropSelection(String crop) {
    if (selectedCrops.contains(crop)) {
      selectedCrops.remove(crop);
    } else {
      selectedCrops.add(crop);
    }
  }

  bool isCropSelected(String crop) => selectedCrops.contains(crop);

  // ── Field validators ───────────────────────────────────────────────────

  String? validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please fill this field';
    if (v.trim().length < 3) return 'Minimum 3 characters required';
    return null;
  }

  // Farmer phone — required, exactly 11 digits
  String? validatePhoneRequired(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please fill this field';
    if (v.trim().length < 11) return 'Phone number must be 11 digits';
    return null;
  }

  // Expert/Company phone — optional, but if filled must be 11 digits
  String? validatePhoneOptional(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length < 11) return 'Phone number must be 11 digits';
    return null;
  }

  String? validateRequired(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please fill this field';
    return null;
  }

  String? validateFarmSize(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (double.tryParse(v.trim()) == null) return 'Numbers only';
    return null;
  }

  String? validateYearsExperience(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please fill this field';
    final years = int.tryParse(v.trim());
    if (years == null || years < 0) return 'Enter a valid number';
    return null;
  }

  String? validateYearsInBusiness(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final years = int.tryParse(v.trim());
    if (years == null || years < 0) return 'Enter a valid number';
    return null;
  }

  // ── Save ───────────────────────────────────────────────────────────────

  Future<void> saveProfile() async {
    autoValidate.value = true;

    final fieldsValid = formKey.currentState?.validate() ?? false;

    // Dropdowns and crops are outside Form — validate manually
    bool extrasValid = true;
    if (selectedRole.value == 'farmer' && selectedCrops.isEmpty) {
      AppSnackbar.error('Please select at least one crop');
      extrasValid = false;
    }
    if (selectedRole.value == 'expert' && selectedSpecialization.value.isEmpty) {
      AppSnackbar.error('Please select your specialization');
      extrasValid = false;
    }
    if (selectedRole.value == 'company' && selectedBusinessType.value.isEmpty) {
      AppSnackbar.error('Please select your business type');
      extrasValid = false;
    }

    if (!fieldsValid || !extrasValid) return;

    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;

    try {
      final current = _authRepository.currentUser.value;
      if (current == null) {
        AppSnackbar.error('Session expired. Please login again.');
        return;
      }

      final name = nameController.text.trim();
      final phone = phoneController.text.trim();
      final location = locationController.text.trim();

      UserModel updated;

      switch (selectedRole.value) {
        case 'farmer':
          updated = current.copyWith(
            name: name,
            phone: phone,
            userType: 'farmer',
            location: location,
            farmSize: farmSizeController.text.trim().isEmpty
                ? null : farmSizeController.text.trim(),
            cropsGrown: selectedCrops.toList(),
            isProfileComplete: true,
            updatedAt: DateTime.now(),
          );
          break;

        case 'expert':
          updated = current.copyWith(
            name: name,
            phone: phone,
            userType: 'expert',
            location: location.isEmpty ? null : location,
            specialization: selectedSpecialization.value,
            yearsOfExperience: int.tryParse(yearsExperienceController.text.trim()),
            certifications: certificationsController.text.trim().isEmpty
                ? null : certificationsController.text.trim(),
            bio: bioController.text.trim().isEmpty
                ? null : bioController.text.trim(),
            isAvailableForConsultation: isAvailableForConsultation.value,
            isProfileComplete: true,
            updatedAt: DateTime.now(),
          );
          break;

        case 'company':
          final ownerName = ownerNameController.text.trim();
          updated = current.copyWith(
            name: ownerName.isEmpty ? name : ownerName,
            phone: phone,
            userType: 'company',
            location: location.isEmpty ? null : location,
            companyName: companyNameController.text.trim(),
            businessType: selectedBusinessType.value,
            yearsInBusiness: int.tryParse(yearsInBusinessController.text.trim()),
            licenseNumber: licenseNumberController.text.trim().isEmpty
                ? null : licenseNumberController.text.trim(),
            businessDescription: businessDescriptionController.text.trim().isEmpty
                ? null : businessDescriptionController.text.trim(),
            isProfileComplete: true,
            updatedAt: DateTime.now(),
          );
          break;

        default:
          AppSnackbar.error('Invalid role selected');
          return;
      }

      await _firebaseService.saveUserData(updated);
      _authRepository.currentUser.value = updated;

      Get.offAllNamed(AppRoutes.HOME);
      Future.delayed(const Duration(milliseconds: 400), () {
        AppSnackbar.success('Profile saved!');
      });
    } catch (e) {
      if (kDebugMode) debugPrint('saveProfile error → $e');
      AppSnackbar.error('Failed to save profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}