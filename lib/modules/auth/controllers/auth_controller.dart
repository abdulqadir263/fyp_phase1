import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/routes/app_routes.dart';

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

  // ✅ NEW: Forgot Password Functionality
  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;

      if (email.isEmpty || !GetUtils.isEmail(email)) {
        Get.snackbar('Error', 'Please enter a valid email address');
        return;
      }

      // Firebase password reset
      await _authProvider.forgotPassword(email);

      Get.snackbar(
        'Success',
        'Password reset link sent to $email',
        duration: Duration(seconds: 5),
      );

      Get.back(); // Go back to login screen

    } catch (e) {
      Get.snackbar('Error', 'Failed to send reset email: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToForgotPassword() {
    if (emailController.text.isEmpty || !GetUtils.isEmail(emailController.text)) {
      Get.snackbar('Error', 'Please enter a valid email address first');
      return;
    }

    print('AuthController: Navigating to forgot password with email: ${emailController.text.trim()}');
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