import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/data/services/firebase_service.dart';

/// AuthRepository — the single source of truth for authentication state.
///
/// Responsibilities:
/// - Holds the current logged-in user (reactive)
/// - Listens to Firebase auth state changes for auto-login on cold start
/// - Delegates all Firebase calls to FirebaseService (no direct Firebase here)
class AuthRepository extends GetxService {
  final FirebaseService _firebase = Get.find<FirebaseService>();

  // --- Reactive state ---
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isAuthenticated = false.obs;

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
    if (kDebugMode) {
      debugPrint('AuthRepository: Auth state changed → ${firebaseUser?.uid}');
    }

    if (firebaseUser == null) {
      currentUser.value = null;
      isAuthenticated.value = false;
      return;
    }

    isAuthenticated.value = true;
    _syncCurrentUser(firebaseUser.uid);
  }

  /// Fetch Firestore user data and update in-memory auth state.
  Future<void> _syncCurrentUser(String uid) async {
    try {
      final userData = await _firebase.getUserData(uid);
      currentUser.value = userData;
    } catch (e) {
      if (kDebugMode) debugPrint('AuthRepository: Error fetching user → $e');
      currentUser.value = null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC AUTH METHODS
  // ─────────────────────────────────────────────────────────────────────────

  /// Register with email + password.
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (kDebugMode) debugPrint('AuthRepository: Signing up → $email');

    final credential = await _firebase.signUpWithEmail(
      email: email,
      password: password,
    );

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
  }

  /// Login with email + password.
  Future<void> signIn({required String email, required String password}) async {
    if (kDebugMode) debugPrint('AuthRepository: Signing in → $email');

    final credential = await _firebase.signInWithEmail(
      email: email,
      password: password,
    );

    final userData = await _firebase.getUserData(credential.user!.uid);
    currentUser.value = userData;
    isAuthenticated.value = true;
  }

  /// Anonymous sign-in for farmer flow.
  Future<void> signInAnonymouslyAsFarmer() async {
    if (kDebugMode) debugPrint('AuthRepository: Anonymous farmer sign-in');

    final credential = await _firebase.signInAnonymously();
    final uid = credential.user!.uid;

    final existing = await _firebase.getUserData(uid);
    if (existing != null) {
      currentUser.value = existing;
      isAuthenticated.value = true;
      return;
    }

    final seededUser = UserModel(
      uid: uid,
      name: '',
      email: '',
      phone: '',
      userType: 'farmer',
      isAnonymous: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isProfileComplete: false,
    );

    await _firebase.saveUserData(seededUser);

    currentUser.value = seededUser;
    isAuthenticated.value = true;
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      if (kDebugMode) debugPrint('AuthRepository: Signing out');

      await _firebase.signOut();

      currentUser.value = null;
      isAuthenticated.value = false;
    } catch (e) {
      if (kDebugMode) debugPrint('AuthRepository: Sign-out error → $e');
    }
  }

  /// Send a password reset email.
  Future<void> forgotPassword(String email) async {
    await _firebase.sendPasswordResetEmail(email);
  }

  /// Re-fetch user data from Firestore.
  Future<void> refreshUserData() async {
    final firebaseUser = _firebase.auth.currentUser;
    if (firebaseUser == null) return;
    await _syncCurrentUser(firebaseUser.uid);
  }
}
