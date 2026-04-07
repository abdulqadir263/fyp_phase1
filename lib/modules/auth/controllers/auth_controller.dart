import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';

/// AuthController — ViewModel for the Login/Signup screen.
///
/// Responsibilities:
/// - Manages form state (text controllers, visibility toggles)
/// - Validates user input before sending to AuthProvider
/// - Manages password reset flow state
/// - Never calls Firebase directly — all auth goes through AuthProvider
class AuthController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();

  // --- Form controllers ---
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;

  // Kept here (not in the view) so it gets properly disposed in onClose()
  late final TextEditingController forgotEmailController;

  // --- UI state ---
  final RxBool isLogin = true.obs; // true = login, false = signup
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  // --- Password reset state ---
  // 0 = enter email step, 1 = success/email-sent step
  final RxInt resetStep = 0.obs;
  final RxString resetEmailSentTo = ''.obs; // the address we sent the link to
  final RxInt resendCooldown = 0.obs; // seconds before resend is allowed
  final RxString selectedRole = ''.obs;

  Timer? _resendTimer;
  Worker? _authStateWorker;
  bool _canNavigate = false;
  bool _isRouting = false;

  @override
  void onInit() {
    super.onInit();

    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    forgotEmailController = TextEditingController();

    _authStateWorker = everAll([
      _authProvider.isAuthenticated,
      _authProvider.currentUser,
    ], (_) => _routeFromAuthState());
  }

  @override
  void onReady() {
    super.onReady();
    // Defer navigation until GetMaterialApp navigator is fully ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canNavigate = true;
      _routeFromAuthState();
    });
  }

  void _routeFromAuthState() {
    if (!_canNavigate || Get.key.currentState == null || _isRouting) return;

    final targetRoute = _resolveAuthRoute();
    if (targetRoute == null) return;

    final currentRoute = Get.currentRoute;
    if (currentRoute == targetRoute) return;

    // Do not force unauthenticated users off public auth pages.
    if (targetRoute == AppRoutes.WELCOME && _isPublicRoute(currentRoute)) {
      return;
    }

    _isRouting = true;
    Future.microtask(() {
      Get.offAllNamed(targetRoute);
      _isRouting = false;
    });
  }

  bool _isPublicRoute(String route) {
    return route == AppRoutes.WELCOME ||
        route == AppRoutes.ROLE_SELECTION ||
        route == AppRoutes.LOGIN ||
        route == AppRoutes.FORGOT_PASSWORD;
  }

  String? _resolveAuthRoute() {
    final UserModel? user = _authProvider.currentUser.value;
    final bool isLoggedIn = _authProvider.isAuthenticated.value && user != null;

    // Unauthenticated: default to welcome, but expert/seller role intent goes to login.
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

    // Anonymous farmer flow
    if (isAnonymousFarmer) {
      return user.isProfileComplete
          ? AppRoutes.HOME
          : AppRoutes.PROFILE_COMPLETION;
    }

    // Expert/Seller flow
    if (!user.isProfileComplete) return AppRoutes.PROFILE;

    return AppRoutes.HOME;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOGGLE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Switch between login and signup modes.
  /// Clears signup-only fields when switching to avoid stale data.
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

  // ─────────────────────────────────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────────────────────────────────

  bool _isValidEmail(String email) =>
      email.isNotEmpty && GetUtils.isEmail(email);

  /// Validates all active form fields.
  /// Shows an error snackbar and returns false on first failure.
  bool _validateForm() {
    if (!isLogin.value) {
      // Signup-only checks
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

  // ─────────────────────────────────────────────────────────────────────────
  // AUTH ACTIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Submit login or signup form.
  Future<void> submit() async {
    if (isLoading.value) return;
    if (!_validateForm()) return;

    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;

    try {
      if (isLogin.value) {
        await _authProvider.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final user = _authProvider.currentUser.value;
        if (user != null && user.name.isNotEmpty) {
          AppSnackbar.success('Welcome back, ${user.name}!');
        } else {
          AppSnackbar.success('Welcome back! Please complete your profile.');
        }
      } else {
        await _authProvider.signUp(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
          password: passwordController.text.trim(),
        );

        AppSnackbar.success('Account created! Please select your role.');
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Start anonymous sign-in for the guest farmer flow.
  Future<void> signInAsGuest() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      await _authProvider.signInAnonymouslyAsFarmer();
    } catch (e) {
      AppSnackbar.error('Could not sign in. Please try again.');
      if (kDebugMode) {
        debugPrint('AuthController: Anonymous sign-in error → $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleRoleSelection(String role) async {
    if (isLoading.value) return;

    selectedRole.value = role;

    // Role selection does not navigate directly. Routing is handled by auth-state resolver.
    if (role == 'farmer' && !_authProvider.isAuthenticated.value) {
      isLoading.value = true;
      try {
        await _authProvider.signInAnonymouslyAsFarmer();
      } catch (e) {
        AppSnackbar.error('Could not sign in. Please try again.');
      } finally {
        isLoading.value = false;
      }
      return;
    }

    _routeFromAuthState();
  }

  void openRoleSelection() => _navigateTo(AppRoutes.ROLE_SELECTION);

  void openWelcome() => _navigateTo(AppRoutes.WELCOME);

  void closeCurrentScreen() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  void _navigateTo(String route) {
    if (!_canNavigate || Get.key.currentState == null) return;
    if (Get.currentRoute == route) return;
    Future.microtask(() => Get.toNamed(route));
  }

  Future<void> signOut() async {
    try {
      await _authProvider.signOut();
      AppSnackbar.success('Logged out successfully.');
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────────────────────────────────────

  /// Navigate to forgot password screen, pre-filling the email field.
  void navigateToForgotPassword() {
    // Reset all state before opening the screen
    resetStep.value = 0;
    resetEmailSentTo.value = '';
    resendCooldown.value = 0;
    // Pre-fill from the login field if the user already typed their email
    forgotEmailController.text = emailController.text.trim();
    Get.toNamed(AppRoutes.FORGOT_PASSWORD);
  }

  /// Send a password reset email.
  /// On success, advances to step 1 and starts the 60-second resend cooldown.
  Future<void> sendPasswordResetEmail(String email) async {
    if (isLoading.value) return;

    if (!_isValidEmail(email)) {
      AppSnackbar.error('Please enter a valid email address');
      return;
    }

    isLoading.value = true;
    try {
      // Routed through AuthProvider — no direct Firebase in this controller
      await _authProvider.forgotPassword(email);
      resetEmailSentTo.value = email;
      resetStep.value = 1;
      _startResendCooldown();
      AppSnackbar.success('Reset link sent to $email');
    } catch (e) {
      AppSnackbar.error('Failed to send reset email. Please try again.');
      if (kDebugMode) debugPrint('AuthController: Reset email error → $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 60-second countdown before the "Resend" button becomes active again.
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
