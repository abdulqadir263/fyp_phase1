import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/routes/app_routes.dart';

/// Controller for handling authentication UI logic
/// Manages login, signup, and password reset forms
class AuthController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();

  // Form Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // UI State
  final RxBool isLogin = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final RxString selectedUserType = 'farmer'.obs;
  
  // Password Reset State
  final RxInt forgotPasswordStep = 0.obs;
  final RxString resetEmail = ''.obs;
  final RxBool isEmailSent = false.obs;
  final RxInt resendTimer = 0.obs;
  
  Timer? _resendTimerInstance;
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    debugPrint('AuthController: Initialized');
  }

  /// Check if email is valid
  bool _isValidEmail(String email) {
    return email.isNotEmpty && GetUtils.isEmail(email);
  }

  /// Toggle between login and signup modes
  void toggleAuthMode() {
    isLogin.value = !isLogin.value;
    
    // Clear signup-only fields when switching to signup mode
    if (!isLogin.value) {
      nameController.clear();
      phoneController.clear();
      confirmPasswordController.clear();
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Validate form fields
  bool validateForm() {
    // Signup-specific validations
    if (!isLogin.value) {
      if (nameController.text.isEmpty || nameController.text.length < 3) {
        _showError('Please enter a valid name (at least 3 characters)');
        return false;
      }

      if (phoneController.text.isEmpty || phoneController.text.length < 11) {
        _showError('Please enter a valid phone number (at least 11 digits)');
        return false;
      }

      if (passwordController.text != confirmPasswordController.text) {
        _showError('Passwords do not match');
        return false;
      }
    }

    // Common validations
    if (!_isValidEmail(emailController.text)) {
      _showError('Please enter a valid email address');
      return false;
    }

    if (passwordController.text.isEmpty || passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return false;
    }

    return true;
  }

  /// Show error snackbar
  void _showError(String message) {
    Get.snackbar('Error', message);
  }

  /// Submit form (login or signup)
  Future<void> submit() async {
    // Prevent double submission
    if (isLoading.value) return;
    if (!validateForm()) return;

    // Dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    isLoading.value = true;

    try {
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
        );
      }
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    if (isLoading.value) return;
    
    if (!_isValidEmail(email)) {
      Get.snackbar(
        'Error', 
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    try {
      isLoading.value = true;

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      resetEmail.value = email;
      isEmailSent.value = true;
      forgotPasswordStep.value = 1;
      _startResendTimer();

      Get.snackbar(
        'Success',
        'Password reset link sent to $email',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      Get.snackbar(
        'Error', 
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } catch (e) {
      Get.snackbar(
        'Error', 
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      debugPrint('Password reset error: $e');
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  /// Get user-friendly error message from Firebase error code
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'invalid-email':
        return 'Invalid email address format';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      default:
        return 'Failed to send reset email';
    }
  }

  /// Start countdown timer for resend button
  void _startResendTimer() {
    _resendTimerInstance?.cancel();
    resendTimer.value = 60;
    
    _resendTimerInstance = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || resendTimer.value <= 0) {
        timer.cancel();
        _resendTimerInstance = null;
        return;
      }
      resendTimer.value--;
    });
  }

  /// Legacy method - redirects to new implementation
  Future<void> forgotPassword(String email) async {
    await sendPasswordResetEmail(email);
  }

  /// Navigate to forgot password screen
  void navigateToForgotPassword() {
    // Reset state before navigating
    forgotPasswordStep.value = 0;
    resetEmail.value = '';
    isEmailSent.value = false;
    resendTimer.value = 0;
    
    Get.toNamed(AppRoutes.FORGOT_PASSWORD, arguments: emailController.text.trim());
  }

  /// Sign in as guest
  void signInAsGuest() {
    _authProvider.signInAsGuest();
  }

  /// Handle user type selection change
  void onUserTypeChanged(String? value) {
    if (value != null) {
      selectedUserType.value = value;
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    _resendTimerInstance?.cancel();
    _resendTimerInstance = null;
    
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}