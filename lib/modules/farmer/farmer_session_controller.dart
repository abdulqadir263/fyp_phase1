import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/routes/app_routes.dart';
import '../../app/utils/app_snackbar.dart';
import '../../app/data/services/farmer_auth_service.dart';

class FarmerSessionController extends GetxController {
  final FarmerAuthService _service = FarmerAuthService();

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

  Future<void> signInAnonymously() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final uid = userCredential.user!.uid;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('farmer_anonymous_uid', uid);

      // Check if profile exists
      final existingProfile = await _service.getFarmerProfile(uid);
      if (existingProfile != null) {
        // Go to home
        Get.offAllNamed(AppRoutes.HOME);
      } else {
        // Go to profile form
        Get.toNamed(AppRoutes.FARMER_SIGNUP); // We'll rename this to FARMER_PROFILE later, or just keep route name to avoid changing too much
      }
    } catch (e) {
      errorMessage.value = e.toString();
      AppSnackbar.error('Failed to sign in anonymously: $e');
    } finally {
      isLoading.value = false;
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
        'farmSize': farmSizeCtrl.text.trim().isEmpty ? null : farmSizeCtrl.text.trim(),
        'cropsGrown': selectedCrops.toList(),
        'userType': 'farmer',
        'isProfileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // saveFarmerProfile must be awaited and wrapped in try/catch
      await _service.saveFarmerProfile(uid: user.uid, data: doc);
      
      Get.offAllNamed(AppRoutes.HOME);
    } catch (e) {
      errorMessage.value = 'Failed to save profile: $e';
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
