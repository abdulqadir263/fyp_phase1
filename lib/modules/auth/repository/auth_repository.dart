import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/data/services/session_service.dart';
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
  Future<void> refreshUserData() async {
    final role = await _session.getCurrentUserRole();
    if (role == null) return;
    final user = _session.currentUser;
    if (user == null) return;

    final data = await _session.getUserData(role, user.uid);
    if (data == null) return;

    // Use SplashController's builder logic, or just a simplified update:
    currentUser.value = UserModel(
      uid: user.uid,
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
      companyName: data['shopName'],
      isProfileComplete: data['isProfileComplete'] ?? true,
      createdAt: currentUser.value?.createdAt ?? DateTime.now(),
    );
  }
}