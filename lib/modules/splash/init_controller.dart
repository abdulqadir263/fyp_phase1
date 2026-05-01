import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/data/models/user_model.dart';
import '../../app/routes/app_routes.dart';
import '../auth/repository/auth_repository.dart';

/// Replaces the old SplashController.
/// This controls the logic on app launch (the SplashView).
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

      // STEP 1: Check SharedPreferences for "farmer_anonymous_uid"
      final farmerUid = prefs.getString('farmer_anonymous_uid');
      if (farmerUid != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == farmerUid) {
          // Fetch farmer profile
          final doc = await FirebaseFirestore.instance
              .collection('farmers')
              .doc(farmerUid)
              .get();
              
          if (doc.exists && doc.data() != null) {
            _authRepo.currentUser.value = _buildUserModel(farmerUid, 'farmer', doc.data()!);
            _authRepo.isAuthenticated.value = true;
            Future.microtask(() => Get.offAllNamed(AppRoutes.HOME));
            return;
          } else {
            // Profile missing, go to setup
            Future.microtask(() => Get.offAllNamed(AppRoutes.FARMER_SIGNUP)); // Using FARMER_SIGNUP to mean profile setup
            return;
          }
        } else {
          // Mismatch or null, clear it
          await prefs.remove('farmer_anonymous_uid');
          _goToWelcome();
          return;
        }
      }

      // STEP 2: Check FirebaseAuth.instance.currentUser (Expert/Seller)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        if (!currentUser.emailVerified) {
          Future.microtask(() => Get.offAllNamed(
                AppRoutes.EMAIL_VERIFICATION_PENDING,
                arguments: {
                  'email': currentUser.email ?? '',
                  'role': _authRepo.currentRole.value.isNotEmpty 
                      ? _authRepo.currentRole.value 
                      : 'unknown',
                  'uid': currentUser.uid,
                },
              ));
          return;
        } else {
          // Email is verified, find the role
          final expertDoc = await FirebaseFirestore.instance
              .collection('experts')
              .doc(currentUser.uid)
              .get();
              
          if (expertDoc.exists && expertDoc.data() != null) {
            _authRepo.currentUser.value = _buildUserModel(currentUser.uid, 'expert', expertDoc.data()!);
            _authRepo.isAuthenticated.value = true;
            Future.microtask(() => Get.offAllNamed(AppRoutes.HOME));
            return;
          }

          final sellerDoc = await FirebaseFirestore.instance
              .collection('sellers')
              .doc(currentUser.uid)
              .get();
              
          if (sellerDoc.exists && sellerDoc.data() != null) {
            _authRepo.currentUser.value = _buildUserModel(currentUser.uid, 'company', sellerDoc.data()!);
            _authRepo.isAuthenticated.value = true;
            Future.microtask(() => Get.offAllNamed(AppRoutes.HOME));
            return;
          }

          // No profile found? Maybe they didn't finish setup.
          final role = _authRepo.currentRole.value;
          if (role == 'expert') {
             Future.microtask(() => Get.offAllNamed(AppRoutes.EXPERT_PROFILE_SETUP));
          } else if (role == 'seller') {
             Future.microtask(() => Get.offAllNamed(AppRoutes.SELLER_PROFILE_SETUP));
          } else {
             _goToWelcome();
          }
          return;
        }
      }

      // STEP 3: Default
      _goToWelcome();
    } catch (e) {
      if (kDebugMode) debugPrint('InitController error: $e');
      _goToWelcome();
    } finally {
      isChecking.value = false;
    }
  }

  void _goToWelcome() {
    Future.microtask(() {
      Get.offAllNamed(AppRoutes.WELCOME);
    });
  }

  UserModel _buildUserModel(
    String uid,
    String role,
    Map<String, dynamic> data,
  ) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
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
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
