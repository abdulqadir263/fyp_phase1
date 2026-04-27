import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/data/models/user_model.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  late final TextEditingController forgotEmailController;

  final RxBool isLogin = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final RxInt resetStep = 0.obs;
  final RxString resetEmailSentTo = ''.obs;
  final RxInt resendCooldown = 0.obs;
  final RxString selectedRole = ''.obs;

  Timer? _resendTimer;
  Worker? _authStateWorker;
  bool _canNavigate = false;
  bool _isRouting = false;
  bool _isSubmitting = false;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    forgotEmailController = TextEditingController();

    // Delay — currentUser Firestore se load hone ka wait
    _authStateWorker = ever(
      _authRepository.isAuthenticated,
          (_) => Future.delayed(
        const Duration(milliseconds: 500),
        _routeFromAuthState,
      ),
    );
  }

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canNavigate = true;
      _routeFromAuthState();
    });
  }

  void _routeFromAuthState() {
    if (!_canNavigate || Get.key.currentState == null || _isRouting) return;

    final currentRoute = Get.currentRoute;
    if (_isStableRoute(currentRoute)) return;

    final targetRoute = _resolveAuthRoute();
    if (targetRoute == null) return;
    if (currentRoute == targetRoute) return;

    if (targetRoute == AppRoutes.WELCOME && _isPublicRoute(currentRoute)) return;

    _isRouting = true;
    Get.offAllNamed(targetRoute);
    Future.delayed(const Duration(milliseconds: 600), () {
      _isRouting = false;
    });
  }

  bool _isPublicRoute(String route) {
    return route == AppRoutes.WELCOME ||
        route == AppRoutes.ROLE_SELECTION ||
        route == AppRoutes.LOGIN ||
        route == AppRoutes.FORGOT_PASSWORD;
  }

  bool _isStableRoute(String route) {
    return route == AppRoutes.HOME ||
        route == AppRoutes.PROFILE_COMPLETION ||
        route == AppRoutes.ROLE_SELECTION ||
        route == AppRoutes.WELCOME;
  }

  String? _resolveAuthRoute() {
    final UserModel? user = _authRepository.currentUser.value;
    final bool isLoggedIn =
        _authRepository.isAuthenticated.value && user != null;

    if (!isLoggedIn) {
      if (selectedRole.value == 'expert' ||
          selectedRole.value == 'company' ||
          selectedRole.value == 'seller') {
        return AppRoutes.LOGIN;
      }
      return AppRoutes.WELCOME;
    }

    final bool isAnonymousFarmer =
        user.isAnonymous || (user.userType == 'farmer' && user.email.isEmpty);

    if (isAnonymousFarmer) {
      return user.isProfileComplete ? AppRoutes.HOME : AppRoutes.PROFILE_COMPLETION;
    }

    if (!user.isProfileComplete) return AppRoutes.PROFILE_COMPLETION;

    return AppRoutes.HOME;
  }

  void toggleAuthMode() {
    isLogin.value = !isLogin.value;
    if (!isLogin.value) {
      nameController.clear();
      phoneController.clear();
      confirmPasswordController.clear();
    }
  }

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;

  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  bool _isValidEmail(String email) =>
      email.isNotEmpty && GetUtils.isEmail(email);

  bool _validateForm() {
    if (!isLogin.value) {
      if (nameController.text.trim().length < 3) {
        AppSnackbar.error('Please enter a valid name (at least 3 characters)');
        return false;
      }
      if (phoneController.text.trim().length < 11) {
        AppSnackbar.error('Please enter a valid phone number');
        return false;
      }
      if (passwordController.text != confirmPasswordController.text) {
        AppSnackbar.error('Passwords do not match');
        return false;
      }
    }
    if (!_isValidEmail(emailController.text)) {
      AppSnackbar.error('Please enter a valid email address');
      return false;
    }
    if (passwordController.text.length < 6) {
      AppSnackbar.error('Password must be at least 6 characters');
      return false;
    }
    return true;
  }

  Future<void> submit() async {
    if (_isSubmitting || isLoading.value) return;
    _isSubmitting = true;
    if (!_validateForm()) {
      _isSubmitting = false;
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;

    try {
      if (isLogin.value) {
        await _authRepository.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        final user = _authRepository.currentUser.value;
        // Delay — navigation complete hone ke baad snackbar
        Future.delayed(const Duration(milliseconds: 500), () {
          if (user != null && user.name.isNotEmpty) {
            AppSnackbar.success('Welcome back, ${user.name}!');
          } else {
            AppSnackbar.success('Welcome back!');
          }
        });
      } else {
        await _authRepository.signUp(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
          password: passwordController.text.trim(),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          AppSnackbar.success('Account created! Please select your role.');
        });
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
      _isSubmitting = false;
    }
  }

  Future<void> signInAsGuest() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _authRepository.signInAnonymouslyAsFarmer();
    } catch (e) {
      AppSnackbar.error('Could not sign in. Please try again.');
      if (kDebugMode) debugPrint('AuthController: Anonymous sign-in error → $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleRoleSelection(String role) async {
    if (isLoading.value) return;
    selectedRole.value = role;

    if (role == 'farmer' && !_authRepository.isAuthenticated.value) {
      isLoading.value = true;
      try {
        await _authRepository.signInAnonymouslyAsFarmer();
      } catch (e) {
        AppSnackbar.error('Could not sign in. Please try again.');
      } finally {
        isLoading.value = false;
      }
      return;
    }

    if (_authRepository.isAuthenticated.value) {
      final currentRoute = Get.currentRoute;
      if (currentRoute != AppRoutes.PROFILE_COMPLETION) {
        _isRouting = true;
        Future.delayed(Duration.zero, () {
          Get.toNamed(AppRoutes.PROFILE_COMPLETION);
          _isRouting = false;
        });
      }
    } else {
      _navigateTo(AppRoutes.LOGIN);
    }
  }

  void openRoleSelection() => _navigateTo(AppRoutes.ROLE_SELECTION);
  void openWelcome() => _navigateTo(AppRoutes.WELCOME);

  void closeCurrentScreen() {
    if (Get.key.currentState?.canPop() ?? false) Get.back();
  }

  void _navigateTo(String route) {
    if (!_canNavigate || Get.key.currentState == null) return;
    if (Get.currentRoute == route) return;
    Future.delayed(Duration.zero, () => Get.toNamed(route));
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
  }

  void navigateToForgotPassword() {
    resetStep.value = 0;
    resetEmailSentTo.value = '';
    resendCooldown.value = 0;
    forgotEmailController.text = emailController.text.trim();
    Get.toNamed(AppRoutes.FORGOT_PASSWORD);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (isLoading.value) return;
    if (!_isValidEmail(email)) {
      AppSnackbar.error('Please enter a valid email address');
      return;
    }
    isLoading.value = true;
    try {
      await _authRepository.forgotPassword(email);
      resetEmailSentTo.value = email;
      resetStep.value = 1;
      _startResendCooldown();
      Future.delayed(const Duration(milliseconds: 300), () {
        AppSnackbar.success('Reset link sent to $email');
      });
    } catch (e) {
      AppSnackbar.error('Failed to send reset email. Please try again.');
      if (kDebugMode) debugPrint('AuthController: Reset email error → $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    resendCooldown.value = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value <= 0) {
        timer.cancel();
        _resendTimer = null;
        return;
      }
      resendCooldown.value--;
    });
  }

  @override
  void onClose() {
    _authStateWorker?.dispose();
    _resendTimer?.cancel();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    forgotEmailController.dispose();
    super.onClose();
  }
}