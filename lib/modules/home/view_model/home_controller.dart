import 'package:flutter/material.dart'; // Import needed for Colors
import 'package:get/get.dart';
import '../../../app/data/models/user_model.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/role_guard.dart';
import '../../../core/localization/language_controller.dart';

/// This controller manages the home screen functionality
/// It handles:
/// - Bottom navigation bar state and navigation
/// - User data and authentication status
/// - Navigation to various app features
/// - Guest user restrictions
class HomeController extends GetxController {
  /// Auth provider to access current user data and authentication methods
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  /// Current index for bottom navigation bar
  /// The 'Rx' makes it reactive - the UI updates automatically when this changes
  final RxInt currentIndex = 0.obs;

  /// Get current user data from auth provider
  Rx<UserModel?> get user => _authRepository.currentUser;

  /// Check if current user is browsing as guest
  bool get isGuestUser => user.value?.userType == 'guest';

  /// Check if user profile is incomplete based on user type
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

  /// Get user's profile image URL
  /// Returns empty string if no profile image is set
  String get profileImageUrl {
    if (user.value == null ||
        user.value!.profileImage == null ||
        user.value!.profileImage!.isEmpty) {
      return '';
    }
    return user.value!.profileImage!;
  }

  /// Refresh user data from Firebase to get updated profile information
  Future<void> refreshUserData() async {
    await _authRepository.refreshUserData();
  }

  /// Role-aware bottom navigation tabs for the current user
  List<String> get bottomNavTabs => RoleGuard.bottomNavTabs;

  /// Handle bottom navigation bar page changes (role-aware)
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

  /// Show logout confirmation dialog and sign out if confirmed
  void logout() {
    Get.defaultDialog(
      title: 'logout'.tr,
      titleStyle: const TextStyle(fontSize: 18),
      middleText: 'logout_confirm'.tr,
      textCancel: 'no'.tr,
      onCancel: () => Get.back(),
      confirm: TextButton(
        style: TextButton.styleFrom(backgroundColor: Get.theme.primaryColor),
        onPressed: () {
          Get.back();
          _authRepository.signOut();
        },
        child: Text(
          'yes'.tr,
          style: TextStyle(color: Get.theme.colorScheme.onPrimary),
        ),
      ),
    );
  }

  /// Navigate to profile screen
  void goToProfile() {
    Get.toNamed(AppRoutes.PROFILE);
  }

  /// Navigate to settings screen (not yet implemented)
  void goToSettings() {
    Get.snackbar('info'.tr, 'settings_coming_soon'.tr);
  }

  /// Navigate to about screen (not yet implemented)
  void goToAbout() {
    Get.snackbar('info'.tr, 'about_coming_soon'.tr);
  }

  /// Toggle app language between English and Urdu
  void toggleLanguage() {
    Get.find<LanguageController>().toggleLanguage();
  }

  /// Show dialog prompting guest users to sign up for restricted features
  void handleGuestUserAccess(String featureName) {
    if (isGuestUser) {
      Get.defaultDialog(
        title: 'signup_required'.tr,
        middleText: 'signup_to_use'.tr,
        textCancel: 'cancel'.tr,
        confirm: TextButton(
          style: TextButton.styleFrom(backgroundColor: Get.theme.primaryColor),
          onPressed: () {
            Get.back();
            Get.offAllNamed(AppRoutes.LOGIN);
          },
          child: Text('sign_up'.tr, style: TextStyle(color: Colors.white)),
        ),
      );
    } else {
      navigateToFeature(featureName);
    }
  }

  /// Navigate to a feature screen based on feature name.
  /// Uses RoleGuard for centralized access control.
  void navigateToFeature(String feature) {
    // Features that require login
    final List<String> restrictedFeatures = [
      'appointments',
      'marketplace',
      'crop_tracker',
      'crop_recommendation',
      'community',
    ];

    // Check if guest user is trying to access restricted feature
    if (isGuestUser && restrictedFeatures.contains(feature)) {
      handleGuestUserAccess(feature);
      return;
    }

    // ── Role-based access check using RoleGuard ──
    final moduleMap = {
      'appointments': RoleGuard.appointments,
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
      // Company accessing marketplace → allow (routes to seller panel)
      final userType = user.value?.userType ?? '';
      if (feature == 'marketplace' && userType == 'company') {
        // Company sees seller dashboard — sellerPanel is the right check
        if (!RoleGuard.canAccess(RoleGuard.sellerPanel, userType)) {
          Get.snackbar('access_denied'.tr, 'no_access_feature'.tr);
          return;
        }
      } else if (!RoleGuard.canAccess(module, userType)) {
        Get.snackbar('access_denied'.tr, 'no_access_feature'.tr);
        return;
      }
    }

    // Navigate to the selected feature
    switch (feature) {
      case 'appointments':
        // Route based on user type: experts see dashboard, farmers see expert list
        if (user.value?.userType == 'expert') {
          Get.toNamed(AppRoutes.EXPERT_DASHBOARD);
        } else {
          Get.toNamed(AppRoutes.APPOINTMENTS);
        }
        break;
      case 'my_visits':
        Get.toNamed(AppRoutes.MY_VISITS);
        break;
      case 'marketplace':
        // Route based on user type: companies see seller dashboard, farmers see buyer marketplace
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
        Get.snackbar('info'.tr, 'disease_detection_coming_soon'.tr);
        break;
      case 'crop_recommendation':
        Get.toNamed(AppRoutes.CROP_RECOMMENDATION);
        break;
      default:
        Get.snackbar('error'.tr, 'feature_not_available'.tr);
    }
  }

  /// Generate personalized welcome message based on time of day (localized)
  String get welcomeMessage {
    final userName = user.value?.name ?? 'farmer'.tr;
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return '${'good_morning'.tr}, $userName! 🌱';
    } else if (hour < 17) {
      return '${'good_afternoon'.tr}, $userName! ☀️';
    } else {
      return '${'good_evening'.tr}, $userName! 🌾';
    }
  }
}
