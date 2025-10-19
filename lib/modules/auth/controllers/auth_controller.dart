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

  // Reactive Variables
  final RxBool isLogin = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs; // Password visibility toggle
  final RxString selectedUserType = 'farmer'.obs;

  @override
  void onInit() {
    super.onInit();
    // Pehle se filled fields ke liye (optional)
    _prefillFieldsForTesting();
  }

  // Testing ke liye fields prefill karna (optional)
  void _prefillFieldsForTesting() {
    // Comment out kar dena production mein
    // nameController.text = 'Test User';
    // emailController.text = 'test@example.com';
    // phoneController.text = '03001234567';
    // passwordController.text = '123456';
  }

  // Login aur signup mode ko toggle karna
  void toggleAuthMode() {
    isLogin.value = !isLogin.value;
    // Fields clear karna mode change par
    if (!isLogin.value) {
      nameController.clear();
      phoneController.clear();
    }
  }

  // Password visibility toggle
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Form validation
  bool validateForm() {
    // Name validation (sirf signup ke liye)
    if (!isLogin.value) {
      if (nameController.text.isEmpty || nameController.text.length < 3) {
        Get.snackbar('Error', 'Please enter a valid name (at least 3 characters)');
        return false;
      }
    }

    // Email validation
    if (emailController.text.isEmpty || !GetUtils.isEmail(emailController.text)) {
      Get.snackbar('Error', 'Please enter a valid email address');
      return false;
    }

    // Password validation
    if (passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter a password');
      return false;
    }

    if (passwordController.text.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters');
      return false;
    }

    // Phone validation (sirf signup ke liye)
    if (!isLogin.value) {
      if (phoneController.text.isEmpty || phoneController.text.length < 11) {
        Get.snackbar('Error', 'Please enter a valid phone number (at least 11 digits)');
        return false;
      }
    }

    return true;
  }

  // ✅ FIXED: Login ya signup function call karna
  Future<void> submit() async {
    if (!validateForm()) return;

    // ✅ FIXED: Safely unfocus keyboard
    if (Get.context != null) {
      FocusScope.of(Get.context!).unfocus();
    }

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

  // ✅ FIXED: Forgot password function
  void forgotPassword() {
    if (emailController.text.isEmpty || !GetUtils.isEmail(emailController.text)) {
      Get.snackbar('Error', 'Please enter a valid email address first');
      return;
    }

    // Email ko pass karte hue forgot password screen par jayein
    Get.toNamed(AppRoutes.FORGOT_PASSWORD, arguments: emailController.text.trim());
  }

  // Guest login function
  void signInAsGuest() {
    _authProvider.signInAsGuest();
  }

  // User type change function
  void onUserTypeChanged(String? value) {
    if (value != null) {
      selectedUserType.value = value;
    }
  }

  // Form reset function
  void resetForm() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    isLogin.value = true;
    selectedUserType.value = 'farmer';
    isPasswordVisible.value = false;
  }

  // Google login function (future ke liye)
  Future<void> signInWithGoogle() async {
    Get.snackbar('Info', 'Google login coming soon!');
    // TODO: Implement Google login
  }

  // Phone login function (future ke liye)
  Future<void> signInWithPhone() async {
    Get.snackbar('Info', 'Phone login coming soon!');
    // TODO: Implement phone login
  }

  @override
  void onClose() {
    // Controllers ko dispose karna memory leak se bachne ke liye
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}