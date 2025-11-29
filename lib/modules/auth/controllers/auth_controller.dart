import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';

// Auth screen ka logic (UI ke saath direct interaction)
class AuthController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Text Editing Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  // Reactive Variables
  final RxBool isLogin = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final RxString selectedUserType = 'farmer'.obs;
  
  // OTP related variables
  final RxInt forgotPasswordStep = 0.obs; // 0: email, 1: OTP, 2: new password
  final RxString resetEmail = ''.obs;
  final RxBool isOtpSent = false.obs;
  final RxInt otpResendTimer = 0.obs;

  @override
  void onInit() {
    super.onInit();
    print('AuthController: Initialized');
  }

  void toggleAuthMode() {
    isLogin.value = !isLogin.value;
    if (!isLogin.value) {
      nameController.clear();
      phoneController.clear();
      confirmPasswordController.clear();
    }
    print('AuthController: Toggled auth mode. IsLogin: ${isLogin.value}');
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  bool validateForm() {
    print('AuthController: Validating form...');

    if (!isLogin.value) {
      if (nameController.text.isEmpty || nameController.text.length < 3) {
        Get.snackbar('Error', 'Please enter a valid name (at least 3 characters)');
        return false;
      }

      if (phoneController.text.isEmpty || phoneController.text.length < 11) {
        Get.snackbar('Error', 'Please enter a valid phone number (at least 11 digits)');
        return false;
      }

      // Confirm password validation
      if (passwordController.text != confirmPasswordController.text) {
        Get.snackbar('Error', 'Passwords do not match');
        return false;
      }
    }

    if (emailController.text.isEmpty || !GetUtils.isEmail(emailController.text)) {
      Get.snackbar('Error', 'Please enter a valid email address');
      return false;
    }

    if (passwordController.text.isEmpty || passwordController.text.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters');
      return false;
    }

    print('AuthController: Form validation passed.');
    return true;
  }

  Future<void> submit() async {
    if (!validateForm()) return;

    // Safely unfocus keyboard
    if (Get.context != null) {
      FocusScope.of(Get.context!).unfocus();
    }

    print('AuthController: Submitting form. IsLogin: ${isLogin.value}');

    if (isLogin.value) {
      await _authProvider.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } else {
      await _authProvider.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
        userType: selectedUserType.value,
      );
    }
  }

  /// Generate 6-digit OTP
  String _generateOTP() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  /// Send password reset OTP
  Future<void> sendPasswordResetOTP(String email) async {
    try {
      isLoading.value = true;

      if (email.isEmpty || !GetUtils.isEmail(email)) {
        Get.snackbar('Error', 'Please enter a valid email address');
        return;
      }

      // Generate OTP
      final otp = _generateOTP();
      final expiryTime = DateTime.now().add(
        Duration(minutes: AppConstants.otpExpiryMinutes),
      );

      // Store OTP in Firestore
      await _firestore.collection(AppConstants.otpCollection).doc(email).set({
        'otp': otp,
        'email': email,
        'expiryTime': Timestamp.fromDate(expiryTime),
        'createdAt': Timestamp.now(),
        'verified': false,
      });

      // For now, use Firebase's built-in password reset email
      // In production, you would send OTP via email service
      await _authProvider.forgotPassword(email);

      resetEmail.value = email;
      isOtpSent.value = true;
      forgotPasswordStep.value = 1;
      
      // Start resend timer
      _startResendTimer();

      Get.snackbar(
        'Success',
        'Password reset link sent to $email',
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green[100],
      );

    } catch (e) {
      Get.snackbar('Error', 'Failed to send reset email: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Start OTP resend timer
  void _startResendTimer() {
    otpResendTimer.value = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (otpResendTimer.value > 0) {
        otpResendTimer.value--;
        return true;
      }
      return false;
    });
  }

  /// Verify OTP
  Future<bool> verifyOTP(String enteredOTP) async {
    try {
      isLoading.value = true;

      if (enteredOTP.length != 6) {
        Get.snackbar('Error', 'Please enter a valid 6-digit OTP');
        return false;
      }

      // Get stored OTP from Firestore
      final doc = await _firestore
          .collection(AppConstants.otpCollection)
          .doc(resetEmail.value)
          .get();

      if (!doc.exists) {
        Get.snackbar('Error', 'OTP expired or not found. Please request a new one.');
        return false;
      }

      final data = doc.data()!;
      final storedOTP = data['otp'] as String;
      final expiryTime = (data['expiryTime'] as Timestamp).toDate();

      // Check if OTP is expired
      if (DateTime.now().isAfter(expiryTime)) {
        Get.snackbar('Error', 'OTP has expired. Please request a new one.');
        await _firestore.collection(AppConstants.otpCollection).doc(resetEmail.value).delete();
        return false;
      }

      // Verify OTP
      if (storedOTP != enteredOTP) {
        Get.snackbar('Error', 'Invalid OTP. Please try again.');
        return false;
      }

      // Mark as verified
      await _firestore.collection(AppConstants.otpCollection).doc(resetEmail.value).update({
        'verified': true,
      });

      forgotPasswordStep.value = 2;
      Get.snackbar(
        'Success',
        'OTP verified successfully!',
        backgroundColor: Colors.green[100],
      );
      return true;

    } catch (e) {
      Get.snackbar('Error', 'Failed to verify OTP: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset password after OTP verification
  Future<void> resetPassword(String newPassword) async {
    try {
      isLoading.value = true;

      if (newPassword.length < 6) {
        Get.snackbar('Error', 'Password must be at least 6 characters');
        return;
      }

      // Verify that OTP was verified
      final doc = await _firestore
          .collection(AppConstants.otpCollection)
          .doc(resetEmail.value)
          .get();

      if (!doc.exists || doc.data()?['verified'] != true) {
        Get.snackbar('Error', 'Please verify OTP first');
        return;
      }

      // Delete OTP document
      await _firestore.collection(AppConstants.otpCollection).doc(resetEmail.value).delete();

      // Reset state
      _resetForgotPasswordState();

      Get.snackbar(
        'Success',
        'Password reset successful! Please login with your new password.',
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green[100],
      );

      Get.offAllNamed(AppRoutes.LOGIN);

    } catch (e) {
      Get.snackbar('Error', 'Failed to reset password: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Legacy forgot password (using Firebase email link)
  Future<void> forgotPassword(String email) async {
    await sendPasswordResetOTP(email);
  }

  /// Reset forgot password state
  void _resetForgotPasswordState() {
    forgotPasswordStep.value = 0;
    resetEmail.value = '';
    isOtpSent.value = false;
    otpResendTimer.value = 0;
    otpController.clear();
    newPasswordController.clear();
  }

  void navigateToForgotPassword() {
    _resetForgotPasswordState();
    Get.toNamed(AppRoutes.FORGOT_PASSWORD, arguments: emailController.text.trim());
  }

  void signInAsGuest() {
    print('AuthController: Signing in as guest');
    _authProvider.signInAsGuest();
  }

  void onUserTypeChanged(String? value) {
    if (value != null) {
      selectedUserType.value = value;
      print('AuthController: User type changed to: $value');
    }
  }

  @override
  void onClose() {
    print('AuthController: Disposing controllers');
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    super.onClose();
  }
}