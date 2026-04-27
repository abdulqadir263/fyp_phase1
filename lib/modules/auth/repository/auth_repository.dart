import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/data/services/firebase_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';

class AuthRepository extends GetxService {
  final FirebaseService _firebase = Get.find<FirebaseService>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    _firebase.authStateChanges.listen(_handleAuthStateChange);
  }

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

  Future<void> _syncCurrentUser(String uid) async {
    try {
      final userData = await _firebase.getUserData(uid);
      currentUser.value = userData;
    } catch (e) {
      if (kDebugMode) debugPrint('AuthRepository: Error fetching user → $e');
      currentUser.value = null;
    }
  }

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

    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      phone: phone,
      userType: '',
      createdAt: DateTime.now(),
      isProfileComplete: false,
    );

    // ✅ Firestore mein save karo — warna _syncCurrentUser null return karta tha
    await _firebase.saveUserData(user);

    currentUser.value = user;
    isAuthenticated.value = true;
  }

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

  Future<void> signOut() async {
    try {
      await _firebase.signOut();
      Get.offAllNamed(AppRoutes.WELCOME);
      Future.delayed(const Duration(milliseconds: 400), () {
        AppSnackbar.success('Logged out successfully.');
      });
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
  }

  Future<void> forgotPassword(String email) async {
    await _firebase.sendPasswordResetEmail(email);
  }

  Future<void> refreshUserData() async {
    final firebaseUser = _firebase.auth.currentUser;
    if (firebaseUser == null) return;
    await _syncCurrentUser(firebaseUser.uid);
  }
}