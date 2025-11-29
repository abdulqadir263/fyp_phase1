import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';

// Auth screen ka logic (UI ke saath direct interaction)
class AuthController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();

  // Text Editing Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Reactive Variables
  final RxBool isLogin = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final RxString selectedUserType = 'farmer'.obs;
  
  // Password reset related variables
  final RxInt forgotPasswordStep = 0.obs; // 0: email, 1: success message
  final RxString resetEmail = ''.obs;
  final RxBool isEmailSent = false.obs;
  final RxInt resendTimer = 0.obs;

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

  /// Send password reset email using Firebase Auth built-in method
  /// This avoids Firestore permission issues by using Firebase Auth directly
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;

      if (email.isEmpty || !GetUtils.isEmail(email)) {
        Get.snackbar(
          'Error', 
          'Please enter a valid email address',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
        return;
      }

      // Use Firebase Auth's built-in password reset - no Firestore write needed
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      resetEmail.value = email;
      isEmailSent.value = true;
      forgotPasswordStep.value = 1;
      
      // Start resend timer
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
      String errorMessage = 'Failed to send reset email';
      
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email address';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address format';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many requests. Please try again later';
      }
      
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
      isLoading.value = false;
    }
  }

  /// Start resend timer for password reset email
  void _startResendTimer() {
    resendTimer.value = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (resendTimer.value > 0) {
        resendTimer.value--;
        return true;
      }
      return false;
    });
  }

  /// Legacy forgot password method - redirects to new implementation
  Future<void> forgotPassword(String email) async {
    await sendPasswordResetEmail(email);
  }

  /// Reset forgot password state
  void _resetForgotPasswordState() {
    forgotPasswordStep.value = 0;
    resetEmail.value = '';
    isEmailSent.value = false;
    resendTimer.value = 0;
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
    super.onClose();
  }
}