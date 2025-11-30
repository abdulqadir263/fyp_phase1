import 'package:flutter/material.dart'; // Import needed for Colors
import 'package:get/get.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/routes/app_routes.dart';

/// This controller manages the home screen functionality
/// It handles:
/// - Bottom navigation bar state and navigation
/// - User data and authentication status
/// - Navigation to various app features
/// - Guest user restrictions
class HomeController extends GetxController {
  /// Auth provider to access current user data and authentication methods
  final AuthProvider _authProvider = Get.find<AuthProvider>();

  /// Current index for bottom navigation bar
  /// The 'Rx' makes it reactive - the UI updates automatically when this changes
  final RxInt currentIndex = 0.obs;

  /// Get current user data from auth provider
  Rx<UserModel?> get user => _authProvider.currentUser;

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
        return userData.specialization == null || userData.specialization!.isEmpty;
      case 'company':
        return userData.companyName == null || userData.companyName!.isEmpty;
      default:
        return false;
    }
  }

  /// Get user's profile image URL
  /// Returns empty string if no profile image is set
  String get profileImageUrl {
    if (user.value == null || user.value!.profileImage == null || user.value!.profileImage!.isEmpty) {
      return '';
    }
    return user.value!.profileImage!;
  }

  /// Refresh user data from Firebase to get updated profile information
  Future<void> refreshUserData() async {
    await _authProvider.refreshUserData();
  }

  /// Handle bottom navigation bar page changes
  /// - Home (0): Shows home content within the home screen
  /// - Marketplace (1): Shows coming soon placeholder
  /// - Weather (2): Navigates to full Weather screen
  /// - Crop Tracker (3): Shows coming soon placeholder
  /// - Community (4): Navigates to full Community screen
  void changePage(int index) {
    switch (index) {
      case 0:
        // Home tab - show home content
        currentIndex.value = index;
        break;
      case 1:
        // Marketplace - not yet implemented, show placeholder
        currentIndex.value = index;
        break;
      case 2:
        // Weather - navigate to Weather screen
        Get.toNamed(AppRoutes.WEATHER);
        break;
      case 3:
        // Crop Tracker - not yet implemented, show placeholder
        currentIndex.value = index;
        break;
      case 4:
        // Community - navigate to Community screen
        Get.toNamed(AppRoutes.COMMUNITY);
        break;
      default:
        currentIndex.value = 0;
    }
  }

  /// Show logout confirmation dialog and sign out if confirmed
  void logout() {
    Get.defaultDialog(
      title: 'Logout',
      titleStyle: const TextStyle(fontSize: 18),
      middleText: 'Are you sure you want to logout?',
      textCancel: 'No',
      onCancel: () => Get.back(),
      confirm: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Get.theme.primaryColor,
        ),
        onPressed: () {
          Get.back();
          _authProvider.signOut();
        },
        child: Text(
          'Yes',
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
    Get.snackbar('Info', 'Settings coming soon!');
  }

  /// Navigate to about screen (not yet implemented)
  void goToAbout() {
    Get.snackbar('Info', 'About coming soon!');
  }

  /// Toggle app language (not yet implemented)
  void toggleLanguage() {
    Get.snackbar('Info', 'Language toggle coming soon!');
  }

  /// Show dialog prompting guest users to sign up for restricted features
  void handleGuestUserAccess(String featureName) {
    if (isGuestUser) {
      Get.defaultDialog(
        title: 'Sign Up Required',
        middleText: 'To use this feature, please create an account or log in.',
        textCancel: 'Cancel',
        confirm: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Get.theme.primaryColor,
          ),
          onPressed: () {
            Get.back();
            Get.offAllNamed(AppRoutes.LOGIN);
          },
          child: const Text(
            'Sign Up',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      navigateToFeature(featureName);
    }
  }

  /// Navigate to a feature screen based on feature name
  /// Some features are restricted for guest users
  void navigateToFeature(String feature) {
    // Features that require login
    final List<String> restrictedFeatures = [
      'appointments',
      'marketplace',
      'crop_tracker',
      'community',
    ];

    // Check if guest user is trying to access restricted feature
    if (isGuestUser && restrictedFeatures.contains(feature)) {
      handleGuestUserAccess(feature);
      return;
    }

    // Navigate to the selected feature
    switch (feature) {
      case 'appointments':
        Get.toNamed(AppRoutes.APPOINTMENTS);
        break;
      case 'marketplace':
        Get.toNamed(AppRoutes.MARKETPLACE);
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
        Get.snackbar('Info', 'Disease Detection coming soon!');
        break;
      case 'crop_recommendation':
        Get.snackbar('Info', 'Crop Recommendation coming soon!');
        break;
      default:
        Get.snackbar('Error', 'Feature not available yet!');
    }
  }

  /// Generate personalized welcome message based on time of day
  String get welcomeMessage {
    final userName = user.value?.name ?? 'Farmer';
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning, $userName! 🌱';
    } else if (hour < 17) {
      return 'Good Afternoon, $userName! ☀️';
    } else {
      return 'Good Evening, $userName! 🌾';
    }
  }
}