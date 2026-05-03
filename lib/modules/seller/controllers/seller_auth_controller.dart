import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/data/models/user_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';
import '../../../modules/auth/repository/auth_repository.dart';
import '../../../modules/auth/services/google_auth_service.dart';
import '../services/seller_auth_service.dart';

class SellerAuthController extends GetxController {
  final SellerAuthService _service = SellerAuthService();
  final GoogleAuthService _googleService = GoogleAuthService();
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  // ── Form controllers ───────────────────────────────────────────────────────
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController passwordCtrl;
  late TextEditingController confirmPasswordCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController shopNameCtrl;
  late TextEditingController ownerNameCtrl;
  late TextEditingController shopLocationCtrl;
  late TextEditingController cnicCtrl;
  late TextEditingController addressCtrl;

  final selectedCategories = <String>[].obs;
  static const productCategories = [
    'Seeds', 'Fertilizers', 'Pesticides',
    'Agricultural Equipment', 'Animal Feed', 'General Agri',
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

  // ── Controller lifecycle flag ──────────────────────────────────────────────
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
  }

  /// Initialize all TextEditingControllers
  void _initializeControllers() {
    nameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    passwordCtrl = TextEditingController();
    confirmPasswordCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    shopNameCtrl = TextEditingController();
    ownerNameCtrl = TextEditingController();
    shopLocationCtrl = TextEditingController();
    cnicCtrl = TextEditingController();
    addressCtrl = TextEditingController();
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  String? validateRequired(String? v, String fieldName) {
    if (v == null || v.trim().isEmpty) return 'Please enter $fieldName';
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

  void toggleCategory(String cat) {
    if (selectedCategories.contains(cat)) {
      selectedCategories.remove(cat);
    } else {
      selectedCategories.add(cat);
    }
  }

  // ── Signup (Email + Password) ──────────────────────────────────────────────

  Future<void> submitSignup() async {
    if (_isDisposed) return;

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

      // Create canonical users/{uid} document
      await _googleService.upsertUserDoc(
        uid: uc.user!.uid,
        email: emailCtrl.text.trim(),
        role: 'seller',
      );

      if (!_isDisposed) {
        Get.toNamed(
          AppRoutes.EMAIL_VERIFICATION_PENDING,
          arguments: {
            'email': emailCtrl.text.trim(),
            'role': 'seller',
            'uid': uc.user!.uid,
          },
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        errorMessage.value = _localizeError(e.toString());
      }
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  // ── Login (Email + Password) ───────────────────────────────────────────────

  Future<void> submitLogin() async {
    if (_isDisposed) return;

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
        if (!_isDisposed) {
          AppSnackbar.error('Please verify your email first.');
          Get.toNamed(
            AppRoutes.EMAIL_VERIFICATION_PENDING,
            arguments: {
              'email': emailCtrl.text.trim(),
              'role': 'seller',
              'uid': uc.user!.uid,
            },
          );
        }
        return;
      }

      // Email verified — check profile
      final data = await _service.getSellerProfile(uc.user!.uid);
      if (!_isDisposed) {
        if (data != null && data['isProfileComplete'] == true) {
          _populateAuthRepoFromMap(uc.user!.uid, data);
          Get.offAllNamed(AppRoutes.HOME);
        } else {
          Get.offAllNamed(AppRoutes.SELLER_PROFILE_SETUP);
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        errorMessage.value = _localizeError(e.toString());
      }
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    if (_isDisposed) return;

    errorMessage.value = '';
    isLoading.value = true;
    try {
      final uc = await _googleService.signInWithGoogleAndVerify();
      if (uc == null) {
        // User cancelled — silent return
        if (!_isDisposed) {
          isLoading.value = false;
        }
        return;
      }

      final uid = uc.user!.uid;
      final email = uc.user?.email ?? '';
      final isNew = uc.additionalUserInfo?.isNewUser ?? false;

      await _googleService.upsertUserDoc(uid: uid, email: email, role: 'seller');

      if (_isDisposed) return;

      // Edge case: new Google account that somehow isn't pre-verified
      if (isNew && !(uc.user?.emailVerified ?? false)) {
        Get.toNamed(
          AppRoutes.EMAIL_VERIFICATION_PENDING,
          arguments: {'email': email, 'role': 'seller', 'uid': uid},
        );
        return;
      }

      // Pre-populate email field for profile setup
      if (!_isDisposed) {
        emailCtrl.text = email;
        _authRepo.setRole('seller');

        final data = await _service.getSellerProfile(uid);
        if (data != null && data['isProfileComplete'] == true) {
          _populateAuthRepoFromMap(uid, data);
          Get.offAllNamed(AppRoutes.HOME);
        } else {
          Get.offAllNamed(AppRoutes.SELLER_PROFILE_SETUP);
        }
      }
    } catch (e) {
      final msg = _googleService.mapError(e);
      if (!_isDisposed && msg.isNotEmpty) {
        errorMessage.value = msg;
      }
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  // ── Profile Setup ──────────────────────────────────────────────────────────

  Future<void> submitProfile() async {
    if (_isDisposed) return;

    errorMessage.value = '';
    if (shopNameCtrl.text.trim().isEmpty) {
      errorMessage.value = 'Please enter your shop name';
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

      await _saveSellerDoc(uid, emailVerified: true);
      await _googleService.markProfileComplete(uid);

      if (!_isDisposed) {
        _populateAuthRepo(uid);
        Get.offAllNamed(AppRoutes.HOME);
      }
    } catch (e) {
      if (!_isDisposed) {
        errorMessage.value = _localizeError(e.toString());
      }
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  // ── Email verification check ───────────────────────────────────────────────

  /// Called from EmailVerificationPendingView.
  /// FIXED: navigates to SELLER_PROFILE_SETUP if profile is not yet complete.
  Future<bool> checkEmailVerified(String uid) async {
    if (_isDisposed) return false;

    final verified = await _service.reloadAndCheckVerification();
    if (verified && !_isDisposed) {
      final data = await _service.getSellerProfile(uid);
      if (!_isDisposed) {
        if (data != null && data['isProfileComplete'] == true) {
          _populateAuthRepoFromMap(uid, data);
          Get.offAllNamed(AppRoutes.HOME);
        } else {
          // Profile not completed yet — go to setup
          Get.offAllNamed(AppRoutes.SELLER_PROFILE_SETUP);
        }
      }
    }
    return verified;
  }

  Future<void> resendVerificationEmail() async {
    if (_isDisposed) return;
    if (resendCooldown.value > 0) return;

    await _service.sendEmailVerification();
    _startResendCooldown();
    if (!_isDisposed) {
      AppSnackbar.success('Verification email sent');
    }
  }

  void _startResendCooldown() {
    resendCooldown.value = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isDisposed || resendCooldown.value <= 0) {
        t.cancel();
      } else {
        resendCooldown.value--;
      }
    });
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _saveSellerDoc(String uid, {required bool emailVerified}) async {
    final email = emailCtrl.text.trim().isNotEmpty
        ? emailCtrl.text.trim()
        : (FirebaseAuth.instance.currentUser?.email ?? '');

    await _service.saveSellerProfile(uid: uid, data: {
      'name': nameCtrl.text.trim(),
      'email': email,
      'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      'shopName': shopNameCtrl.text.trim(),
      'shopLocation': shopLocationCtrl.text.trim().isEmpty ? null : shopLocationCtrl.text.trim(),
      'productCategories': selectedCategories.toList(),
      'emailVerified': emailVerified,
      'userType': 'company',
      'isProfileComplete': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _populateAuthRepo(String uid) {
    final email = emailCtrl.text.trim().isNotEmpty
        ? emailCtrl.text.trim()
        : (FirebaseAuth.instance.currentUser?.email ?? '');
    _authRepo.currentUser.value = UserModel(
      uid: uid,
      name: nameCtrl.text.trim(),
      email: email,
      phone: phoneCtrl.text.trim(),
      userType: 'company',
      companyName: shopNameCtrl.text.trim(),
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
      userType: 'company',
      companyName: data['shopName'],
      isProfileComplete: data['isProfileComplete'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
    _authRepo.isAuthenticated.value = true;
  }

  String _localizeError(String code) {
    if (code.contains('email_already_in_use')) return 'This email is already registered.';
    if (code.contains('wrong_password') || code.contains('invalid-credential')) return 'Incorrect email or password.';
    if (code.contains('user_not_found')) return 'No account found. Please sign up.';
    if (code.contains('weak_password')) return 'Password too weak.';
    if (code.contains('too_many_requests')) return 'Too many attempts. Please wait.';
    if (code.contains('network_error')) return 'Network error. Check your connection.';
    return 'Something went wrong. Please try again.';
  }

  @override
  void onClose() {
    _isDisposed = true;
    _resendTimer?.cancel();

    // Safely dispose all controllers
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    phoneCtrl.dispose();
    shopNameCtrl.dispose();
    ownerNameCtrl.dispose();
    shopLocationCtrl.dispose();
    cnicCtrl.dispose();
    addressCtrl.dispose();

    super.onClose();
  }
}