import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../../utils/app_snackbar.dart';

/// AuthProvider — the single source of truth for authentication state.
///
/// Responsibilities:
/// - Holds the current logged-in user (reactive)
/// - Listens to Firebase auth state changes for auto-login on cold start
/// - Delegates all Firebase calls to FirebaseService (no direct Firebase here)
/// - Routes user to the correct screen after login
class AuthProvider extends GetxService {
  final FirebaseService _firebase = Get.find<FirebaseService>();

  // --- Reactive state ---
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isAuthenticated = false.obs;

  // --- Internal navigation guards ---
  // Prevents the auth stream listener from navigating during an active login/signup.
  bool _isSigningIn = false;
  // Ensures cold-start auto-navigation only happens once.
  bool _initialRouteHandled = false;

  @override
  void onInit() {
    super.onInit();
    // Listen to Firebase auth state — handles auto-login on cold start
    _firebase.authStateChanges.listen(_handleAuthStateChange);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUTH STATE LISTENER
  // ─────────────────────────────────────────────────────────────────────────

  /// Called by Firebase whenever auth state changes (login, logout, cold start).
  void _handleAuthStateChange(User? firebaseUser) {
    if (kDebugMode) debugPrint('AuthProvider: Auth state changed → ${firebaseUser?.uid}');

    if (firebaseUser == null) {
      // User signed out — clear state
      currentUser.value = null;
      isAuthenticated.value = false;
      return;
    }

    // During active sign-in/signup, those methods handle their own navigation.
    // Skip auto-routing to avoid a double-navigate race condition.
    if (_isSigningIn) return;

    // Cold start: only auto-route once
    if (_initialRouteHandled) return;
    _initialRouteHandled = true;

    _fetchUserAndRoute(firebaseUser.uid);
  }

  /// Fetch Firestore user data and route to the correct screen.
  Future<void> _fetchUserAndRoute(String uid) async {
    try {
      final userData = await _firebase.getUserData(uid);

      if (userData != null) {
        currentUser.value = userData;
        isAuthenticated.value = true;
        _routeAfterAuth(userData);
      } else {
        // User is authenticated (Firebase) but has no Firestore profile yet.
        // This happens for new signups or anonymous users who haven't completed onboarding.
        isAuthenticated.value = true;
        Get.offAllNamed(AppRoutes.ROLE_SELECTION);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AuthProvider: Error fetching user → $e');
      AppSnackbar.error('Failed to load user data. Please try again.');
    }
  }

  /// Routes to Home or Role Selection based on profile completion status.
  void _routeAfterAuth(UserModel user) {
    if (user.isProfileComplete == false) {
      Get.offAllNamed(AppRoutes.PROFILE_COMPLETION);
    } else {
      Get.offAllNamed(AppRoutes.HOME);
    }
  }

  /// Checks if the user has completed their role-specific profile setup.
  bool _isProfileComplete(UserModel user) {
    // Prefer the explicit flag set during onboarding
    if (user.isProfileComplete) return true;

    // Fallback for existing users created before the flag was added
    if (user.name.isEmpty || user.userType.isEmpty) return false;

    switch (user.userType) {
      case 'farmer':
        return (user.location?.isNotEmpty ?? false) &&
               (user.cropsGrown?.isNotEmpty ?? false);
      case 'expert':
        return (user.specialization?.isNotEmpty ?? false) &&
               user.yearsOfExperience != null;
      case 'company':
        return (user.companyName?.isNotEmpty ?? false) &&
               (user.businessType?.isNotEmpty ?? false);
      default:
        return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC AUTH METHODS
  // ─────────────────────────────────────────────────────────────────────────

  /// Register with email + password.
  /// After signup, user goes to Role Selection to complete their profile.
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      _isSigningIn = true;
      _initialRouteHandled = true;

      if (kDebugMode) debugPrint('AuthProvider: Signing up → $email');

      final credential = await _firebase.signUpWithEmail(
        email: email,
        password: password,
      );

      // Hold basic info in memory — Firestore doc is written after profile completion
      currentUser.value = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        userType: '',
        createdAt: DateTime.now(),
        isProfileComplete: false,
      );
      isAuthenticated.value = true;

      AppSnackbar.success('Account created! Please select your role.');
      Get.offAllNamed(AppRoutes.ROLE_SELECTION);
    } catch (e) {
      if (kDebugMode) debugPrint('AuthProvider: Sign-up error → $e');
      AppSnackbar.error(e.toString());
    } finally {
      _isSigningIn = false;
    }
  }

  /// Login with email + password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isSigningIn = true;
      _initialRouteHandled = true;

      if (kDebugMode) debugPrint('AuthProvider: Signing in → $email');

      final credential = await _firebase.signInWithEmail(
        email: email,
        password: password,
      );

      final userData = await _firebase.getUserData(credential.user!.uid);

      if (userData != null) {
        currentUser.value = userData;
        isAuthenticated.value = true;
        AppSnackbar.success('Welcome back, ${userData.name}!');
        _routeAfterAuth(userData);
      } else {
        // Authenticated but no profile — guide them through onboarding
        isAuthenticated.value = true;
        AppSnackbar.success('Welcome back! Please complete your profile.');
        Get.offAllNamed(AppRoutes.ROLE_SELECTION);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AuthProvider: Sign-in error → $e');
      AppSnackbar.error(e.toString());
    } finally {
      _isSigningIn = false;
    }
  }

  /// Anonymous sign-in for the guest farmer flow.
  ///
  /// The user gets a real Firebase UID — their data persists across app restarts.
  /// After anonymous auth, they must pick a role and complete their profile.
  Future<void> signInAnonymously() async {
    try {
      _isSigningIn = true;
      _initialRouteHandled = true;

      if (kDebugMode) debugPrint('AuthProvider: Anonymous sign-in');

      final credential = await _firebase.signInAnonymously();
      final uid = credential.user!.uid;

      // Check if this anonymous user has completed onboarding before (returning user)
      final existing = await _firebase.getUserData(uid);
      if (existing != null) {
        currentUser.value = existing;
        isAuthenticated.value = true;
        _routeAfterAuth(existing);
        return;
      }

      // New anonymous user — hold minimal state, Firestore doc written after profile
      currentUser.value = UserModel(
        uid: uid,
        name: '',
        email: '',
        phone: '',
        userType: '',
        isAnonymous: true,
        createdAt: DateTime.now(),
        isProfileComplete: false,
      );
      isAuthenticated.value = true;

      // Anonymous users must complete onboarding before accessing the app
      Get.offAllNamed(AppRoutes.ROLE_SELECTION);
    } catch (e) {
      if (kDebugMode) debugPrint('AuthProvider: Anonymous sign-in error → $e');
      AppSnackbar.error('Could not sign in. Please try again.');
    } finally {
      _isSigningIn = false;
    }
  }

  /// Sign out the current user (email or anonymous).
  Future<void> signOut() async {
    try {
      if (kDebugMode) debugPrint('AuthProvider: Signing out');

      await _firebase.signOut();

      // Reset all state and guards
      currentUser.value = null;
      isAuthenticated.value = false;
      _initialRouteHandled = false;

      Get.offAllNamed(AppRoutes.LOGIN);
      AppSnackbar.success('Logged out successfully.');
    } catch (e) {
      if (kDebugMode) debugPrint('AuthProvider: Sign-out error → $e');
      AppSnackbar.error(e.toString());
    }
  }

  /// Send a password reset email. Called by AuthController.
  Future<void> forgotPassword(String email) async {
    // Throws on error — let the controller handle UI feedback
    await _firebase.sendPasswordResetEmail(email);
  }

  /// Re-fetch user data from Firestore and update in-memory state.
  /// Used after profile updates that originate outside this provider.
  Future<void> refreshUserData() async {
    final firebaseUser = _firebase.auth.currentUser;
    if (firebaseUser == null) return;
    await _fetchUserAndRoute(firebaseUser.uid);
  }
}