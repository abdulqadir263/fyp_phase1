import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/data/models/user_model.dart';
import '../../app/routes/app_routes.dart';
import '../auth/repository/auth_repository.dart';

/// Controls the logic on app launch (SplashView).
/// Restores the active session regardless of auth method:
///   • Anonymous farmer  (farmer_anonymous_uid in prefs)
///   • Email/Password or Google farmer (current_role == 'farmer')
///   • Expert / Seller with email verification
class InitController extends GetxController {
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  final isChecking = true.obs;

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ── STEP 1: Anonymous farmer ──────────────────────────────────────────
      final farmerAnonUid = prefs.getString('farmer_anonymous_uid');
      if (farmerAnonUid != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == farmerAnonUid) {
          final doc = await FirebaseFirestore.instance
              .collection('farmers')
              .doc(farmerAnonUid)
              .get();

          if (doc.exists && doc.data() != null) {
            _authRepo.currentUser.value =
                _buildUserModel(farmerAnonUid, 'farmer', doc.data()!);
            _authRepo.isAuthenticated.value = true;
            Future.microtask(() => Get.offAllNamed(AppRoutes.HOME));
          } else {
            Future.microtask(() => Get.offAllNamed(AppRoutes.FARMER_SIGNUP));
          }
          return;
        }
        // Stale anonymous UID — remove it
        await prefs.remove('farmer_anonymous_uid');
      }

      // ── STEP 2: No Firebase session at all ───────────────────────────────
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _goToWelcome();
        return;
      }

      await currentUser.reload();
      final savedRole = prefs.getString('current_role') ?? '';

      // ── STEP 3: Farmer with email/password or Google ──────────────────────
      if (savedRole == 'farmer') {
        final doc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          _authRepo.currentUser.value =
              _buildUserModel(currentUser.uid, 'farmer', doc.data()!);
          _authRepo.isAuthenticated.value = true;
          Future.microtask(() => Get.offAllNamed(AppRoutes.HOME));
        } else {
          Future.microtask(() => Get.offAllNamed(AppRoutes.FARMER_SIGNUP));
        }
        return;
      }

      // ── STEP 4: Expert / Seller — require email verification ─────────────
      if (!FirebaseAuth.instance.currentUser!.emailVerified) {
        Future.microtask(() => Get.offAllNamed(
              AppRoutes.EMAIL_VERIFICATION_PENDING,
              arguments: {
                'email': currentUser.email ?? '',
                'role': savedRole.isNotEmpty ? savedRole : 'unknown',
                'uid': currentUser.uid,
              },
            ));
        return;
      }

      // Expert profile?
      final expertDoc = await FirebaseFirestore.instance
          .collection('experts')
          .doc(currentUser.uid)
          .get();
      if (expertDoc.exists && expertDoc.data() != null) {
        _authRepo.currentUser.value =
            _buildUserModel(currentUser.uid, 'expert', expertDoc.data()!);
        _authRepo.isAuthenticated.value = true;
        Future.microtask(() => Get.offAllNamed(AppRoutes.HOME));
        return;
      }

      // Seller profile?
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(currentUser.uid)
          .get();
      if (sellerDoc.exists && sellerDoc.data() != null) {
        _authRepo.currentUser.value =
            _buildUserModel(currentUser.uid, 'company', sellerDoc.data()!);
        _authRepo.isAuthenticated.value = true;
        Future.microtask(() => Get.offAllNamed(AppRoutes.HOME));
        return;
      }

      // Verified but profile incomplete — resume setup
      if (savedRole == 'expert') {
        Future.microtask(() => Get.offAllNamed(AppRoutes.EXPERT_PROFILE_SETUP));
      } else if (savedRole == 'seller') {
        Future.microtask(() => Get.offAllNamed(AppRoutes.SELLER_PROFILE_SETUP));
      } else {
        _goToWelcome();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('InitController error: $e');
      _goToWelcome();
    } finally {
      isChecking.value = false;
    }
  }

  void _goToWelcome() {
    Future.microtask(() => Get.offAllNamed(AppRoutes.WELCOME));
  }

  UserModel _buildUserModel(
    String uid,
    String role,
    Map<String, dynamic> data,
  ) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '',
      phone: data['phone'] ?? '',
      userType: role,
      location: data['farmLocation'] ?? data['location'],
      farmSize: data['farmSize'],
      cropsGrown: data['cropsGrown'] != null
          ? List<String>.from(data['cropsGrown'])
          : null,
      specialization: data['specialization'],
      companyName: data['shopName'],
      isProfileComplete: data['isProfileComplete'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
