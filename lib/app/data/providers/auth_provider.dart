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
    
    if (user == null) {
      // User logged out - clear state
      currentUser.value = null;
      isAuthenticated.value = false;
      return;
    }

    // Only auto-fetch on app start, not during active sign-in
    // (sign-in handles its own navigation)
    if (!_isSigningIn) {
      _fetchAndNavigate(user.uid);
    }
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
        debugPrint('AuthProvider: No user data found');
        currentUser.value = null;
        isAuthenticated.value = false;
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
      debugPrint('AuthProvider: Navigating to PROFILE');
      Get.offAllNamed(AppRoutes.PROFILE);
    }
  }

  /// Check if user profile has required fields filled
  bool _isProfileComplete(UserModel user) {
    // Basic required fields
    if (user.name.isEmpty || user.email.isEmpty || user.phone.isEmpty) {
      return false;
    }

    // Check user-type specific fields
    switch (user.userType) {
      case 'farmer':
        return user.location != null && user.location!.isNotEmpty;
      case 'expert':
        return user.specialization != null && user.specialization!.isNotEmpty;
      case 'company':
        return user.companyName != null && user.companyName!.isNotEmpty;
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
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String userType,
  }) async {
    try {
      isLoading.value = true;
      debugPrint('AuthProvider: Starting signup for: $email');

      // Validate inputs
      if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || userType.isEmpty) {
        throw Exception('All fields are required for signup.');
      }

      // Create user in Firebase Auth
      final userCredential = await _firebaseService.signUpWithEmail(
        email: email,
        password: password,
      );

      debugPrint('AuthProvider: User created: ${userCredential.user?.uid}');

      // Save user data to Firestore
      final newUser = UserModel(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        userType: userType,
        createdAt: DateTime.now(),
      );

      await _firebaseService.saveUserData(newUser);
      debugPrint('AuthProvider: User data saved to Firestore');

      AppSnackbar.success('Account created successfully! Please login to continue.');
      
      // Redirect to login
      Get.offAllNamed(AppRoutes.LOGIN);
    } catch (e) {
      debugPrint('AuthProvider: Signup error: $e');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
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
      debugPrint('AuthProvider: Starting sign-in for: $email');

      // Authenticate with Firebase
      final userCredential = await _firebaseService.signInWithEmail(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Sign-in failed: No user returned');
      }

      debugPrint('AuthProvider: Sign-in successful, fetching user data');
      
      // Fetch user data from Firestore
      final userData = await _firebaseService.getUserData(user.uid);

      if (userData != null) {
        // Update state
        currentUser.value = userData;
        isAuthenticated.value = true;
        
        AppSnackbar.success('Login successful!');
        
        // Navigate to appropriate screen
        _navigateAfterAuth(userData);
      } else {
        // User authenticated but no Firestore data - unusual case
        debugPrint('AuthProvider: No user data in Firestore');
        AppSnackbar.error('User data not found. Please contact support.');
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