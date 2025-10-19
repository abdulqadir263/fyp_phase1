import 'package:flutter/material.dart'; // Import needed for Colors
import 'package:get/get.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/routes/app_routes.dart';

// Home screen ka logic (UI ke saath interaction)
class HomeController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();

  // Bottom navigation ke liye current index
  final RxInt currentIndex = 0.obs;

  // Current user ka data
  Rx<UserModel?> get user => _authProvider.currentUser;

  // ✅ NEW: Check if current user is guest
  bool get isGuestUser => user.value?.userType == 'guest';

  // ✅ NEW: Check if profile is incomplete
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

  // ✅ NEW: Get profile image URL
  String get profileImageUrl {
    if (user.value == null || user.value!.profileImage == null || user.value!.profileImage!.isEmpty) {
      return ''; // Return empty string if no profile image
    }
    return user.value!.profileImage!;
  }

  // ✅ NEW: Refresh user data to get updated profile image
  Future<void> refreshUserData() async {
    await _authProvider.refreshUserData();
  }

  // Page change karne ke liye function
  void changePage(int index) {
    currentIndex.value = index;
  }

  // Logout function
  void logout() {
    Get.defaultDialog(
      title: 'Logout',
      titleStyle: const TextStyle(fontSize: 18), // This parameter is still valid
      middleText: 'Are you sure you want to logout?',
      textCancel: 'No',
      onCancel: () => Get.back(), // Dialog close karo

      // ✅ FIXED: Use the 'confirm' property for custom styling and actions
      confirm: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Get.theme.primaryColor, // Optional: for background
        ),
        onPressed: () {
          Get.back(); // Dialog close karo
          _authProvider.signOut();
        },
        child: Text(
          'Yes',
          style: TextStyle(color: Get.theme.colorScheme.onPrimary),
        ),
      ),
    );
  }

  // Profile screen par jana
  void goToProfile() {
    Get.toNamed(AppRoutes.PROFILE);
  }

  // Settings screen par jana
  void goToSettings() {
    Get.snackbar('Info', 'Settings coming soon!');
  }

  // About screen par jana
  void goToAbout() {
    Get.snackbar('Info', 'About coming soon!');
  }

  // Language toggle function (future ke liye)
  void toggleLanguage() {
    Get.snackbar('Info', 'Language toggle coming soon!');
    // TODO: Implement language toggle logic
  }

  // ✅ NEW: Handle guest user trying to access restricted features
  void handleGuestUserAccess(String featureName) {
    if (isGuestUser) {
      Get.defaultDialog(
        title: 'Sign Up Required',
        middleText: 'To use this feature, please create an account or log in.',
        textCancel: 'Cancel',

        // ✅ FIXED: Use the 'confirm' property to style the button and set its action
        confirm: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Get.theme.primaryColor, // Optional: for background
          ),
          onPressed: () {
            Get.back(); // Close dialog
            Get.offAllNamed(AppRoutes.LOGIN); // Go to login screen
          },
          child: const Text(
            'Sign Up',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      // If not a guest, proceed with normal navigation
      navigateToFeature(featureName);
    }
  }

  // ✅ UPDATED: Modified navigateToFeature to check for guest user
  void navigateToFeature(String feature) {
    // Features that require login
    final List<String> restrictedFeatures = [
      'appointments',
      'marketplace',
      'crop_tracker',
      'community',
    ];

    if (isGuestUser && restrictedFeatures.contains(feature)) {
      handleGuestUserAccess(feature);
      return;
    }

    // Normal navigation for logged-in users or non-restricted features
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

  // Welcome message generate karna
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