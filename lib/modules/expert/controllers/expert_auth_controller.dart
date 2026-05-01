import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/data/models/user_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';
import '../../../modules/auth/repository/auth_repository.dart';
import '../services/expert_auth_service.dart';

class ExpertAuthController extends GetxController {
  final ExpertAuthService _service = ExpertAuthService();
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  // ── Form controllers ───────────────────────────────────────────────────────
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final phoneCtrl = TextEditingController(); // optional, contact only
  final locationCtrl = TextEditingController();
  final yearsExpCtrl = TextEditingController();
  final certificationsCtrl = TextEditingController();
  final bioCtrl = TextEditingController();

  final selectedSpecialization = ''.obs;
  final isAvailableForConsultation = true.obs;
  final selectedDays = <String>[].obs;
  final selectedSlots = <String>[].obs;
  final consultationFeeCtrl = TextEditingController();
  final selectedConsultationMode = 'Both'.obs;

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

  static const specializations = [
    'Crop Management', 'Pest & Disease Control', 'Soil Science',
    'Irrigation Systems', 'Livestock Management', 'Agricultural Machinery',
    'Agri Business & Marketing', 'Organic Farming',
    'Fertilizer & Nutrient Management',
  ];

  // ── UI state ───────────────────────────────────────────────────────────────
  final isLogin = false.obs;
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final errorMessage = ''.obs;

  // ── Resend cooldown ────────────────────────────────────────────────────────
  final resendCooldown = 0.obs;
  Timer? _resendTimer;

  // ── Validation ─────────────────────────────────────────────────────────────
  String? validateName(String? v) {
    if (v == null || v.trim().length < 3) return 'Minimum 3 characters';
    return null;
  }

  String? validateEmail(String? v) {
    if (v == null || !GetUtils.isEmail(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? validateYears(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter years of experience';
    if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
    return null;
  }

  // ── Signup (Auth only) ─────────────────────────────────────────────────────

  Future<void> submitSignup() async {
    errorMessage.value = '';
    if (!GetUtils.isEmail(emailCtrl.text.trim())) {
      errorMessage.value = 'Please enter a valid email';
      return;
    }
    if (passwordCtrl.text.length < 8) {
      errorMessage.value = 'Password must be at least 8 characters';
      return;
    }
    if (passwordCtrl.text != confirmPasswordCtrl.text) {
      errorMessage.value = 'Passwords do not match';
      return;
    }

    isLoading.value = true;
    try {
      final uc = await _service.signUpWithEmail(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
      );
      await _service.sendEmailVerification();
      
      Get.toNamed(
        AppRoutes.EMAIL_VERIFICATION_PENDING,
        arguments: {
          'email': emailCtrl.text.trim(),
          'role': 'expert',
          'uid': uc.user!.uid,
        },
      );
    } catch (e) {
      errorMessage.value = _localizeError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<void> submitLogin() async {
    errorMessage.value = '';
    if (!GetUtils.isEmail(emailCtrl.text.trim())) {
      errorMessage.value = 'Please enter a valid email';
      return;
    }
    if (passwordCtrl.text.isEmpty) {
      errorMessage.value = 'Please enter your password';
      return;
    }

    isLoading.value = true;
    try {
      final uc = await _service.signInWithEmail(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
      );
      if (!(uc.user?.emailVerified ?? false)) {
        await _service.sendEmailVerification();
        AppSnackbar.error('Please verify your email first.');
        Get.toNamed(
          AppRoutes.EMAIL_VERIFICATION_PENDING,
          arguments: {
            'email': emailCtrl.text.trim(),
            'role': 'expert',
            'uid': uc.user!.uid,
          },
        );
        return;
      }
      
      // Email is verified, check if profile exists
      final data = await _service.getExpertProfile(uc.user!.uid);
      if (data != null) {
        _populateAuthRepoFromMap(uc.user!.uid, data);
        Get.offAllNamed(AppRoutes.HOME);
      } else {
        Get.offAllNamed(AppRoutes.EXPERT_PROFILE_SETUP);
      }
    } catch (e) {
      errorMessage.value = _localizeError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ── Profile Setup ──────────────────────────────────────────────────────────

  Future<void> submitProfile() async {
    errorMessage.value = '';
    if (nameCtrl.text.trim().length < 3) {
      errorMessage.value = 'Please enter your full name';
      return;
    }
    if (selectedSpecialization.value.isEmpty) {
      errorMessage.value = 'Please select your specialization';
      return;
    }
    if (yearsExpCtrl.text.trim().isEmpty) {
      errorMessage.value = 'Please enter years of experience';
      return;
    }
    if (selectedDays.isEmpty) {
      errorMessage.value = 'Please select at least one available day';
      return;
    }
    if (selectedSlots.isEmpty) {
      errorMessage.value = 'Please select at least one time slot';
      return;
    }

    isLoading.value = true;
    try {
      final uid = _authRepo.currentUser.value?.uid ??
                  FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        errorMessage.value = 'Session lost. Please log in again.';
        return;
      }

      await _saveExpertDoc(uid, emailVerified: true);
      _populateAuthRepo(uid);
      Get.offAllNamed(AppRoutes.HOME);
    } catch (e) {
      errorMessage.value = _localizeError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ── Email verification check ───────────────────────────────────────────────

  Future<bool> checkEmailVerified(String uid) async {
    final verified = await _service.reloadAndCheckVerification();
    if (verified) {
      await _service.saveExpertProfile(
        uid: uid,
        data: {'emailVerified': true},
      );
      final data = await _service.getExpertProfile(uid);
      if (data != null) _populateAuthRepoFromMap(uid, data);
      Get.offAllNamed(AppRoutes.HOME);
    }
    return verified;
  }

  Future<void> resendVerificationEmail() async {
    if (resendCooldown.value > 0) return;
    await _service.sendEmailVerification();
    _startResendCooldown();
    AppSnackbar.success('Verification email sent');
  }

  void _startResendCooldown() {
    resendCooldown.value = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendCooldown.value <= 0) {
        t.cancel();
      } else {
        resendCooldown.value--;
      }
    });
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _saveExpertDoc(String uid, {required bool emailVerified}) async {
    await _service.saveExpertProfile(uid: uid, data: {
      'name': nameCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      'location': locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
      'specialization': selectedSpecialization.value,
      'yearsOfExperience': int.tryParse(yearsExpCtrl.text.trim()) ?? 0,
      'certifications': certificationsCtrl.text.trim().isEmpty ? null : certificationsCtrl.text.trim(),
      'bio': bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
      'isAvailableForConsultation': isAvailableForConsultation.value,
      'availableDays': selectedDays.toList(),
      'availableSlots': selectedSlots.toList(),
      'consultationFee': int.tryParse(consultationFeeCtrl.text.trim()) ?? 0,
      'consultationMode': selectedConsultationMode.value,
      'emailVerified': emailVerified,
      'userType': 'expert',
      'isProfileComplete': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _populateAuthRepo(String uid) {
    _authRepo.currentUser.value = UserModel(
      uid: uid,
      name: nameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      userType: 'expert',
      specialization: selectedSpecialization.value,
      yearsOfExperience: int.tryParse(yearsExpCtrl.text.trim()),
      isAvailableForConsultation: isAvailableForConsultation.value,
      availableDays: selectedDays.toList(),
      availableSlots: selectedSlots.toList(),
      consultationFee: int.tryParse(consultationFeeCtrl.text.trim()) ?? 0,
      consultationMode: selectedConsultationMode.value,
      isProfileComplete: true,
      createdAt: DateTime.now(),
    );
    _authRepo.isAuthenticated.value = true;
  }

  void _populateAuthRepoFromMap(String uid, Map<String, dynamic> data) {
    _authRepo.currentUser.value = UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      userType: 'expert',
      specialization: data['specialization'],
      yearsOfExperience: data['yearsOfExperience'],
      isProfileComplete: data['isProfileComplete'] ?? true,
      isAvailableForConsultation: data['isAvailableForConsultation'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
    _authRepo.isAuthenticated.value = true;
  }

  String _localizeError(String code) {
    if (code.contains('email_already_in_use')) return 'This email is already registered.';
    if (code.contains('wrong_password') || code.contains('invalid-credential')) return 'Incorrect email or password.';
    if (code.contains('user_not_found')) return 'No account found. Please sign up.';
    if (code.contains('weak_password')) return 'Password too weak. Use at least 8 characters.';
    if (code.contains('too_many_requests')) return 'Too many attempts. Please wait.';
    if (code.contains('network_error')) return 'Network error. Check your connection.';
    return 'Something went wrong. Please try again.';
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    phoneCtrl.dispose();
    locationCtrl.dispose();
    yearsExpCtrl.dispose();
    certificationsCtrl.dispose();
    bioCtrl.dispose();
    consultationFeeCtrl.dispose();
    super.onClose();
  }
}
