import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/data/services/session_service.dart';
import '../../../app/data/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/routes/app_routes.dart';/// Single source of truth for the *currently active user state* in the app.
/// It no longer performs auth itself (the role-specific controllers do that),
/// but it holds `currentUser` so the UI (Home, Community, etc.) stays happy.
class AuthRepository extends GetxService {
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isAuthenticated = false.obs;

  final SessionService _session = SessionService();

  final RxString currentRole = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    currentRole.value = prefs.getString('current_role') ?? '';
  }

  void setRole(String role) async {
    currentRole.value = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_role', role);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('farmer_anonymous_uid');
    await prefs.remove('current_role');
    await _session.signOut();
    currentUser.value = null;
    isAuthenticated.value = false;
    currentRole.value = '';
    Get.offAllNamed(AppRoutes.WELCOME);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signInWithEmail(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> reloadAndCheckVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      return FirebaseAuth.instance.currentUser!.emailVerified;
    }
    return false;
  }

  Future<bool> hasProfile(String role, String uid) async {
    final doc = await FirebaseFirestore.instance.collection('${role}s').doc(uid).get();
    return doc.exists;
  }

  /// Called after profile updates in edit_profile, etc.
  /// Reads from the canonical `users` collection so all extended fields are
  /// preserved. Falls back to role-specific data if not found there yet.
  Future<void> refreshUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    // Primary: read full UserModel from `users` collection
    try {
      final firebaseService = Get.find<FirebaseService>();
      final fresh = await firebaseService.getUserData(firebaseUser.uid);
      if (fresh != null) {
        currentUser.value = fresh;
        return;
      }
    } catch (_) {}

    // Fallback: reconstruct from role-specific collection (first-login before
    // any profile save)
    final role = await _session.getCurrentUserRole();
    if (role == null) return;
    final fbUser = _session.currentUser;
    if (fbUser == null) return;
    final data = await _session.getUserData(role, fbUser.uid);
    if (data == null) return;

    currentUser.value = UserModel(
      uid: fbUser.uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      userType: role == 'seller' ? 'company' : role,
      location: data['farmLocation'] ?? data['location'],
      farmSize: data['farmSize'],
      cropsGrown: data['cropsGrown'] != null
          ? List<String>.from(data['cropsGrown'])
          : null,
      specialization: data['specialization'],
      companyName: data['shopName'] ?? data['companyName'],
      profileImage: data['profileImage'],
      yearsOfExperience: data['yearsOfExperience'] as int?,
      certifications: data['certifications'],
      bio: data['bio'],
      isAvailableForConsultation: data['isAvailableForConsultation'] as bool?,
      availableDays: data['availableDays'] != null
          ? List<String>.from(data['availableDays'])
          : null,
      availableSlots: data['availableSlots'] != null
          ? List<String>.from(data['availableSlots'])
          : null,
      consultationFee: data['consultationFee'] as int?,
      consultationMode: data['consultationMode'],
      businessType: data['businessType'],
      yearsInBusiness: data['yearsInBusiness'] as int?,
      licenseNumber: data['licenseNumber'],
      businessDescription: data['businessDescription'],
      isProfileComplete: data['isProfileComplete'] ?? true,
      createdAt: currentUser.value?.createdAt ?? DateTime.now(),
    );
  }
}