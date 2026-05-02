import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/data/models/user_model.dart';
import '../../app/data/services/farmer_auth_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/utils/app_snackbar.dart';
import '../../modules/auth/repository/auth_repository.dart';
import '../../modules/auth/services/google_auth_service.dart';

class FarmerSessionController extends GetxController {
  final FarmerAuthService _service = FarmerAuthService();
  final GoogleAuthService _googleService = GoogleAuthService();
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  // Profile fields
  final nameCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final farmSizeCtrl = TextEditingController();

  final selectedCrops = <String>[].obs;
  static const availableCrops = [
    'Wheat', 'Rice', 'Potatoes', 'Maize',
    'Cotton', 'Sugarcane', 'Canola',
  ];

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  void toggleCrop(String crop) {
    if (selectedCrops.contains(crop)) {
      selectedCrops.remove(crop);
    } else {
      selectedCrops.add(crop);
    }
  }

  Future<void> submitProfile() async {
    errorMessage.value = '';
    if (nameCtrl.text.trim().length < 3) {
      errorMessage.value = 'Please enter your full name (min 3 chars)';
      return;
    }
    if (locationCtrl.text.trim().isEmpty) {
      errorMessage.value = 'Please enter your farm location';
      return;
    }
    if (selectedCrops.isEmpty) {
      errorMessage.value = 'Please select at least one crop';
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      errorMessage.value = 'Not authenticated';
      return;
    }

    isLoading.value = true;
    try {
      final doc = <String, dynamic>{
        'name': nameCtrl.text.trim(),
        'farmLocation': locationCtrl.text.trim(),
        'farmSize': farmSizeCtrl.text.trim().isEmpty
            ? null
            : farmSizeCtrl.text.trim(),
        'cropsGrown': selectedCrops.toList(),
        'userType': 'farmer',
        'isProfileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _service.saveFarmerProfile(uid: user.uid, data: doc);

      // Mark canonical users/{uid} as profileComplete
      await _googleService.markProfileComplete(user.uid);

      // Populate AuthRepository so the home screen has the user model
      _authRepo.currentUser.value = UserModel(
        uid: user.uid,
        name: nameCtrl.text.trim(),
        email: user.email ?? '',
        phone: '',
        userType: 'farmer',
        location: locationCtrl.text.trim(),
        farmSize: farmSizeCtrl.text.trim().isEmpty
            ? null
            : farmSizeCtrl.text.trim(),
        cropsGrown: selectedCrops.toList(),
        isProfileComplete: true,
        createdAt: DateTime.now(),
      );
      _authRepo.isAuthenticated.value = true;

      Get.offAllNamed(AppRoutes.HOME);
    } catch (e) {
      errorMessage.value = 'Failed to save profile: $e';
      AppSnackbar.error(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    locationCtrl.dispose();
    farmSizeCtrl.dispose();
    super.onClose();
  }
}
