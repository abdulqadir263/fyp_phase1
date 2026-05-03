import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/data/models/user_model.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/role_guard.dart';
import '../../../core/localization/language_controller.dart';

class HomeController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final RxInt currentIndex = 0.obs;

  Rx<UserModel?> get user => _authRepository.currentUser;
  bool get isGuestUser => user.value?.userType == 'guest';

  bool get isProfileIncomplete {
    final userData = user.value;
    if (userData == null || userData.userType == 'guest') return false;
    switch (userData.userType) {
      case 'farmer':
        return userData.location == null || userData.location!.isEmpty;
      case 'expert':
        return userData.specialization == null ||
            userData.specialization!.isEmpty;
      case 'company':
        return userData.companyName == null || userData.companyName!.isEmpty;
      default:
        return false;
    }
  }

  String get profileImageUrl {
    if (user.value == null ||
        user.value!.profileImage == null ||
        user.value!.profileImage!.isEmpty) return '';
    return user.value!.profileImage!;
  }

  Future<void> refreshUserData() async {
    await _authRepository.refreshUserData();
  }

  List<String> get bottomNavTabs => RoleGuard.bottomNavTabs;

  void changePage(int index) {
    final tabs = bottomNavTabs;
    if (index < 0 || index >= tabs.length) return;
    final tab = tabs[index];
    switch (tab) {
      case 'home':
        currentIndex.value = index;
        break;
      case 'marketplace':
        if (user.value?.userType == 'company') {
          Get.toNamed(AppRoutes.SELLER_DASHBOARD);
        } else {
          Get.toNamed(AppRoutes.MARKETPLACE);
        }
        break;
      case 'disease_detection':
        Get.toNamed(AppRoutes.DISEASE_DETECTION);
        break;
      case 'weather':
        Get.toNamed(AppRoutes.WEATHER);
        break;
      case 'crop_tracker':
        currentIndex.value = index;
        break;
      case 'community':
        Get.toNamed(AppRoutes.COMMUNITY);
        break;
      case 'appointments':
        currentIndex.value = index;
        if (user.value?.userType == 'expert') {
          Get.toNamed(AppRoutes.EXPERT_DASHBOARD);
        } else {
          Get.toNamed(AppRoutes.APPOINTMENTS);
        }
        break;
      default:
        currentIndex.value = 0;
    }
  }

  @override
  void onInit() {
    super.onInit();
    ever(_authRepository.currentUser, (_) => update());
  }

  @override
  void onReady() {
    super.onReady();
    refreshUserData();
  }

  void logout() {
    Get.defaultDialog(
      title: 'logout'.tr,
      titleStyle: const TextStyle(fontSize: 18),
      middleText: 'logout_confirm'.tr,
      textCancel: 'no'.tr,
      textConfirm: 'yes'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        _authRepository.signOut();
      },
    );
  }

  void goToProfile() => Get.toNamed(AppRoutes.PROFILE);

  void goToSettings() => Get.snackbar('info'.tr, 'settings_coming_soon'.tr);

  void goToAbout() => Get.snackbar('info'.tr, 'about_coming_soon'.tr);

  void toggleLanguage() => Get.find<LanguageController>().toggleLanguage();

  void handleGuestUserAccess(String featureName) {
    if (isGuestUser) {
      Get.defaultDialog(
        title: 'signup_required'.tr,
        middleText: 'signup_to_use'.tr,
        textCancel: 'cancel'.tr,
        textConfirm: 'sign_up'.tr,
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back();
          Get.offAllNamed(AppRoutes.WELCOME);
        },
      );
    } else {
      navigateToFeature(featureName);
    }
  }

  void navigateToFeature(String feature) {
    final List<String> restrictedFeatures = [
      'appointments',
      'my_appointments',
      'marketplace',
      'crop_tracker',
      'crop_recommendation',
      'community',
    ];

    if (isGuestUser && restrictedFeatures.contains(feature)) {
      handleGuestUserAccess(feature);
      return;
    }

    final moduleMap = {
      'appointments': RoleGuard.appointments,
      'my_appointments': RoleGuard.appointments,
      'my_visits': RoleGuard.appointments,
      'marketplace': RoleGuard.marketplace,
      'weather': RoleGuard.weather,
      'crop_tracker': RoleGuard.cropTracker,
      'crop_recommendation': RoleGuard.cropRecommendation,
      'community': RoleGuard.community,
      'chatbot': RoleGuard.chatbot,
    };

    final module = moduleMap[feature];
    if (module != null) {
      final userType = user.value?.userType ?? '';
      if (feature == 'marketplace' && userType == 'company') {
        if (!RoleGuard.canAccess(RoleGuard.sellerPanel, userType)) {
          Get.snackbar('access_denied'.tr, 'no_access_feature'.tr);
          return;
        }
      } else if (!RoleGuard.canAccess(module, userType)) {
        Get.snackbar('access_denied'.tr, 'no_access_feature'.tr);
        return;
      }
    }

    switch (feature) {
      case 'appointments':
      // "Book" — goes to expert list (farmer) or field visits (expert)
        if (user.value?.userType == 'expert') {
          Get.toNamed(AppRoutes.EXPERT_DASHBOARD);
        } else {
          Get.toNamed(AppRoutes.APPOINTMENTS);
        }
        break;

    // ── NEW: My Appointments history ──────────────────────────────────────
      case 'my_appointments':
        if (user.value?.userType == 'expert') {
          Get.toNamed(AppRoutes.EXPERT_APPOINTMENTS);
        } else {
          Get.toNamed(AppRoutes.FARMER_APPOINTMENTS);
        }
        break;
    // ─────────────────────────────────────────────────────────────────────

      case 'my_visits':
        Get.toNamed(AppRoutes.MY_VISITS);
        break;
      case 'marketplace':
        if (user.value?.userType == 'company') {
          Get.toNamed(AppRoutes.SELLER_DASHBOARD);
        } else {
          Get.toNamed(AppRoutes.MARKETPLACE);
        }
        break;
      case 'weather':
        Get.toNamed(AppRoutes.WEATHER);
        break;
      case 'crop_tracker':
        Get.toNamed(AppRoutes.CROP_TRACKER);
        break;
      case 'community':
        Get.toNamed(AppRoutes.COMMUNITY);
        break;
      case 'chatbot':
        Get.toNamed(AppRoutes.CHATBOT);
        break;
      case 'disease_detection':
        Get.toNamed(AppRoutes.DISEASE_DETECTION);
        break;
      case 'crop_recommendation':
        Get.toNamed(AppRoutes.CROP_RECOMMENDATION);
        break;
      default:
        Get.snackbar('error'.tr, 'feature_not_available'.tr);
    }
  }

  String get welcomeMessage {
    final userName = user.value?.name ?? 'farmer'.tr;
    final hour = DateTime.now().hour;
    if (hour < 12) return '${'good_morning'.tr}, $userName! 🌱';
    if (hour < 17) return '${'good_afternoon'.tr}, $userName! ☀️';
    return '${'good_evening'.tr}, $userName! 🌾';
  }
}