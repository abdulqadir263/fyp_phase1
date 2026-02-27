import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../../utils/app_snackbar.dart';

/// Auth Provider - Manages authentication state and user data
/// Bridge between controllers and Firebase service
class AuthProvider extends GetxService {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  // Observable state
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  // Track if sign-in is in progress to prevent duplicate navigation
  bool _isSigningIn = false;

  // Prevents the authStateChanges listener from auto-navigating on cold start.
  // Only explicit signIn/signUp/signOut actions should trigger navigation.
  bool _initialRouteHandled = false;

  // Guest session flag — guest lives only in memory, not in Firebase Auth.
  // When true, authStateChanges listener is completely bypassed.
  bool _isGuest = false;

  @override
  void onInit() {
    super.onInit();
    debugPrint('AuthProvider: Initialized');

    // Listen to auth state changes for auto-login on app start
    _firebaseService.authStateChanges.listen(_handleAuthStateChange);
  }

  /// Handle auth state changes from Firebase
  void _handleAuthStateChange(User? user) {
    debugPrint('AuthProvider: Auth state changed. User: ${user?.uid}');

    // If guest is active, completely ignore Firebase auth state changes
    if (_isGuest) {
      debugPrint('AuthProvider: Guest mode active, ignoring auth state change');
      return;
    }

    if (user == null) {
      // User logged out - clear state
      currentUser.value = null;
      isAuthenticated.value = false;
      return;
    }

    // Only auto-navigate on the FIRST auth state event (cold start).
    // During active sign-in/signup, those methods handle their own navigation.
    if (_isSigningIn) {
      debugPrint('AuthProvider: Sign-in in progress, skipping auto-navigate');
      return;
    }

    // Guard: only handle initial route once (prevents login screen blink)
    if (_initialRouteHandled) {
      debugPrint('AuthProvider: Initial route already handled, skipping');
      return;
    }
    _initialRouteHandled = true;

    _fetchAndNavigate(user.uid);
  }

  /// Fetch user data and navigate to appropriate screen
  Future<void> _fetchAndNavigate(String uid) async {
    try {
      isLoading.value = true;
      debugPrint('AuthProvider: Fetching user data for: $uid');

      final userData = await _firebaseService.getUserData(uid);

      if (userData != null) {
        debugPrint('AuthProvider: User found - ${userData.name}');
        currentUser.value = userData;
        isAuthenticated.value = true;
        
        // Navigate based on profile completion
        _navigateAfterAuth(userData);
      } else {
        // User authenticated but no Firestore data — likely a new signup
        // that hasn't completed the onboarding flow yet
        debugPrint('AuthProvider: No user data found, navigating to role selection');
        isAuthenticated.value = true;
        Get.offAllNamed(AppRoutes.ROLE_SELECTION);
      }
    } catch (e) {
      debugPrint('AuthProvider: Error fetching user data: $e');
      AppSnackbar.error('Failed to fetch user data');
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to appropriate screen after authentication
  void _navigateAfterAuth(UserModel user) {
    final isComplete = _isProfileComplete(user);
    debugPrint('AuthProvider: Profile complete: $isComplete');

    if (isComplete) {
      debugPrint('AuthProvider: Navigating to HOME');
      Get.offAllNamed(AppRoutes.HOME);
    } else {
         // If profile not complete, go to role selection
      debugPrint('AuthProvider: Navigating to ROLE_SELECTION');
      Get.offAllNamed(AppRoutes.ROLE_SELECTION);
    }
  }

  /// Check if user profile has required fields filled
  /// Updated to use the new isProfileComplete flag
  bool _isProfileComplete(UserModel user) {
    // First check the explicit flag
    if (user.isProfileComplete) {
      return true;
    }

    // Fallback: Check user-type specific fields for backwards compatibility
    // Basic required fields
    if (user.name.isEmpty || user.email.isEmpty) {
      return false;
    }

    // Check user-type specific fields
    switch (user.userType) {
      case 'farmer':
        // Farmer needs location and at least one crop
        return (user.location != null && user.location!.isNotEmpty) &&
               (user.cropsGrown != null && user.cropsGrown!.isNotEmpty);
      case 'expert':
        // Expert needs specialization and years of experience
        return (user.specialization != null && user.specialization!.isNotEmpty) &&
               (user.yearsOfExperience != null);
      case 'company':
        // Company needs company name and business type
        return (user.companyName != null && user.companyName!.isNotEmpty) &&
               (user.businessType != null && user.businessType!.isNotEmpty);
      case 'guest':
        return true; // Guests are always "complete"
      default:
        return false;
    }
  }

  /// Refresh user data (public method for profile updates)
  Future<void> refreshUserData() async {
    final user = _firebaseService.auth.currentUser;
    if (user != null) {
      debugPrint('AuthProvider: Refreshing user data');
      await _fetchAndNavigate(user.uid);
    }
  }

  /// Sign up with email and password
  /// After successful signup, navigates to RoleSelectionView for role selection
  /// NOTE: No Firestore profile document is created here.
  /// Profile is created AFTER role selection + profile completion.
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      _isSigningIn = true;
      // Mark initial route as handled so authStateChanges won't double-navigate
      _initialRouteHandled = true;
      debugPrint('AuthProvider: Starting signup for: $email');

      // Validate inputs
      if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
        throw Exception('All fields are required for signup.');
      }

      // Create user in Firebase Auth only — no Firestore doc yet
      final userCredential = await _firebaseService.signUpWithEmail(
        email: email,
        password: password,
      );

      debugPrint('AuthProvider: User created: ${userCredential.user?.uid}');

      // Hold basic user info in memory for the onboarding flow
      // Firestore document will be created after profile completion
      currentUser.value = UserModel(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        userType: '', // Will be set during role selection
        createdAt: DateTime.now(),
        isProfileComplete: false,
      );
      isAuthenticated.value = true;

      AppSnackbar.success('Account created! Please select your role.');

      // Navigate to Role Selection screen
      Get.offAllNamed(AppRoutes.ROLE_SELECTION);
    } catch (e) {
      debugPrint('AuthProvider: Signup error: $e');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
      _isSigningIn = false;
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      _isSigningIn = true;
      // Mark initial route as handled so authStateChanges won't double-navigate
      _initialRouteHandled = true;
      debugPrint('AuthProvider: Starting sign-in for: $email');

      // Authenticate with Firebase
      final userCredential = await _firebaseService.signInWithEmail(
        email: email,
        password: password,
      );

      debugPrint('AuthProvider: Sign-in successful, fetching user data');
      
      // Fetch user data from Firestore
      final userData = await _firebaseService.getUserData(userCredential.user!.uid);

      if (userData != null) {
        // Update state
        currentUser.value = userData;
        isAuthenticated.value = true;
        
        AppSnackbar.success('Login successful!');
        
        // Navigate to appropriate screen
        _navigateAfterAuth(userData);
      } else {
        // User authenticated but no Firestore data — likely incomplete onboarding
        // Navigate to role selection so they can complete their profile
        debugPrint('AuthProvider: No Firestore data, navigating to role selection');
        isAuthenticated.value = true;
        AppSnackbar.success('Welcome back! Please complete your profile.');
        Get.offAllNamed(AppRoutes.ROLE_SELECTION);
      }
    } catch (e) {
      debugPrint('AuthProvider: Sign-in error: $e');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
      _isSigningIn = false;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      debugPrint('AuthProvider: Signing out');

      // Reset all navigation guards so next login works correctly
      _isGuest = false;
      _initialRouteHandled = false;

      await _firebaseService.signOut();
      
      // Clear state
      currentUser.value = null;
      isAuthenticated.value = false;

      Get.offAllNamed(AppRoutes.LOGIN);
      AppSnackbar.success('Logged out successfully!');
    } catch (e) {
      debugPrint('AuthProvider: Sign-out error: $e');
      AppSnackbar.error(e.toString());
    }
  }

  /// Sign in as guest user
  Future<void> signInAsGuest() async {
    try {
      debugPrint('AuthProvider: Signing in as guest');

      // Set guest flag BEFORE changing any state so the listener ignores events
      _isGuest = true;
      _initialRouteHandled = true;

      currentUser.value = UserModel(
        uid: 'guest_user',
        name: 'Guest User',
        email: 'guest@example.com',
        phone: '',
        userType: 'guest',
        createdAt: DateTime.now(),
      );
      isAuthenticated.value = true;

      Get.offAllNamed(AppRoutes.HOME);
      AppSnackbar.success('Logged in as Guest!');
    } catch (e) {
      debugPrint('AuthProvider: Guest sign-in error: $e');
      AppSnackbar.error(e.toString());
    }
  }

  /// Send password reset email
  Future<void> forgotPassword(String email) async {
    try {
      debugPrint('AuthProvider: Sending password reset email to: $email');
      await _firebaseService.sendPasswordResetEmail(email);
      debugPrint('AuthProvider: Password reset email sent');
    } catch (e) {
      debugPrint('AuthProvider: Password reset error: $e');
      rethrow;
    }
  }
}