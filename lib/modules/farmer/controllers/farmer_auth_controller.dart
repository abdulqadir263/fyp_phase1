import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/data/models/user_model.dart';
import '../../../app/data/services/farmer_auth_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';
import '../../../modules/auth/repository/auth_repository.dart';
import '../../../modules/auth/services/google_auth_service.dart';

/// Handles all three farmer sign-in methods:
///   1. Anonymous (guest) — original flow preserved
///   2. Email + Password — no email verification required for farmers
///   3. Google Sign-In    — no email verification required for farmers
class FarmerAuthController extends GetxController {
  final FarmerAuthService _service = FarmerAuthService();
  final GoogleAuthService _googleService = GoogleAuthService();
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  // ── Email / Password form fields ──────────────────────────────────────────
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  // ── UI state ───────────────────────────────────────────────────────────────
  final isLogin = true.obs;
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final errorMessage = ''.obs;

  // ── Validation ─────────────────────────────────────────────────────────────
  String? validateEmail(String? v) {
    if (v == null || !GetUtils.isEmail(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.length < 8) return 'Minimum 8 characters';
    return null;
  }

  // ── 1. Anonymous (Guest) ──────────────────────────────────────────────────

  Future<void> signInAnonymously() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final uc = await FirebaseAuth.instance.signInAnonymously();
      final uid = uc.user!.uid;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('farmer_anonymous_uid', uid);
      _authRepo.setRole('farmer');

      // Create canonical users/{uid} doc (no email for anonymous)
      await _googleService.upsertUserDoc(uid: uid, email: '', role: 'farmer');

      await _navigateAfterFarmerAuth(uid);
    } catch (e) {
      errorMessage.value = 'Guest sign-in failed. Please try again.';
      AppSnackbar.error(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // ── 2. Email + Password ────────────────────────────────────────────────────

  Future<void> submitEmailAuth() async {
    errorMessage.value = '';
    if (!GetUtils.isEmail(emailCtrl.text.trim())) {
      errorMessage.value = 'Please enter a valid email';
      return;
    }
    if (passwordCtrl.text.length < 8) {
      errorMessage.value = 'Password must be at least 8 characters';
      return;
    }
    if (!isLogin.value && passwordCtrl.text != confirmPasswordCtrl.text) {
      errorMessage.value = 'Passwords do not match';
      return;
    }

    isLoading.value = true;
    try {
      UserCredential uc;
      if (isLogin.value) {
        uc = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text,
        );
      } else {
        uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text,
        );
      }

      final uid = uc.user!.uid;
      _authRepo.setRole('farmer');

      // Farmers do NOT require email verification
      await _googleService.upsertUserDoc(
        uid: uid,
        email: emailCtrl.text.trim(),
        role: 'farmer',
      );

      await _navigateAfterFarmerAuth(uid);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _localizeError(e.code);
    } catch (e) {
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── 3. Google Sign-In ─────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final uc = await _googleService.signInWithGoogle();
      if (uc == null) {
        // User cancelled
        isLoading.value = false;
        return;
      }

      final uid = uc.user!.uid;
      final email = uc.user?.email ?? '';
      _authRepo.setRole('farmer');

      await _googleService.upsertUserDoc(uid: uid, email: email, role: 'farmer');

      await _navigateAfterFarmerAuth(uid);
    } catch (e) {
      final msg = _googleService.mapError(e);
      if (msg.isNotEmpty) errorMessage.value = msg;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Shared post-auth navigation ───────────────────────────────────────────

  Future<void> _navigateAfterFarmerAuth(String uid) async {
    final profile = await _service.getFarmerProfile(uid);
    if (profile != null) {
      _populateAuthRepoFromMap(uid, profile);
      Get.offAllNamed(AppRoutes.HOME);
    } else {
      Get.toNamed(AppRoutes.FARMER_SIGNUP);
    }
  }

  void _populateAuthRepoFromMap(String uid, Map<String, dynamic> data) {
    _authRepo.currentUser.value = UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ??
          FirebaseAuth.instance.currentUser?.email ??
          '',
      phone: data['phone'] ?? '',
      userType: 'farmer',
      location: data['farmLocation'],
      farmSize: data['farmSize'],
      cropsGrown: data['cropsGrown'] != null
          ? List<String>.from(data['cropsGrown'])
          : null,
      isProfileComplete: data['isProfileComplete'] ?? true,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
    _authRepo.isAuthenticated.value = true;
  }

  String _localizeError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-not-found':
        return 'No account found. Please sign up.';
      case 'weak-password':
        return 'Password too weak. Use at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }
}
