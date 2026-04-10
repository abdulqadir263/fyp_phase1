import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../app/routes/app_routes.dart';
import '../../app/utils/app_snackbar.dart';

/// Centralized role-based access control for the entire app.
///
/// Defines which modules each user type can access.
/// Used by: route middleware, controllers, navigation UI.
class RoleGuard {
  RoleGuard._(); // Prevent instantiation

  // ═══════════════════════════════════════════
  //  MODULE IDENTIFIERS
  // ═══════════════════════════════════════════

  static const String marketplace = 'marketplace';
  static const String sellerPanel = 'seller_panel';
  static const String cart = 'cart';
  static const String appointments = 'appointments';
  static const String community = 'community';
  static const String weather = 'weather';
  static const String chatbot = 'chatbot';
  static const String profile = 'profile';
  static const String cropTracker = 'crop_tracker';
  static const String cropRecommendation = 'crop_recommendation';

  // ═══════════════════════════════════════════
  //  ACCESS MATRIX
  // ═══════════════════════════════════════════

  /// Defines which modules each role can access
  static const Map<String, Set<String>> _accessMatrix = {
    'farmer': {
      marketplace,
      cart,
      appointments,
      community,
      weather,
      chatbot,
      profile,
      cropTracker,
      cropRecommendation,
    },
    'expert': {appointments, community, chatbot, profile},
    'company': {marketplace, sellerPanel, chatbot, profile},
    'guest': {weather, chatbot},
  };

  // ═══════════════════════════════════════════
  //  CORE ACCESS CHECK
  // ═══════════════════════════════════════════

  /// Check if a given userType can access a module
  static bool canAccess(String module, String userType) {
    final allowed = _accessMatrix[userType];
    if (allowed == null) return false;
    return allowed.contains(module);
  }

  /// Get the current user's type from AuthRepository
  static String get currentUserType {
    try {
      return Get.find<AuthRepository>().currentUser.value?.userType ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  /// Check access for the currently logged-in user
  static bool currentUserCanAccess(String module) {
    return canAccess(module, currentUserType);
  }

  // ═══════════════════════════════════════════
  //  DEFAULT REDIRECT ROUTES PER ROLE
  // ═══════════════════════════════════════════

  /// Where to redirect when a role tries to access something unauthorized
  static String defaultRouteFor(String userType) {
    switch (userType) {
      case 'company':
        return AppRoutes.SELLER_DASHBOARD;
      case 'expert':
        return AppRoutes.EXPERT_DASHBOARD;
      case 'farmer':
        return AppRoutes.HOME;
      default:
        return AppRoutes.HOME;
    }
  }

  /// Default route for the current user
  static String get currentDefaultRoute => defaultRouteFor(currentUserType);

  // ═══════════════════════════════════════════
  //  ROUTE → MODULE MAPPING
  // ═══════════════════════════════════════════

  /// Maps route paths to their required module permission.
  /// Routes not listed here are unrestricted (auth, home, profile, etc.)
  static String? moduleForRoute(String route) {
    // Marketplace buyer routes
    if (route == AppRoutes.MARKETPLACE ||
        route == AppRoutes.MARKETPLACE_PRODUCT ||
        route == AppRoutes.ORDER_HISTORY ||
        route == AppRoutes.ORDER_DETAIL) {
      return marketplace;
    }

    // Cart / Checkout — only buyers (farmer)
    if (route == AppRoutes.MARKETPLACE_CART ||
        route == AppRoutes.MARKETPLACE_CHECKOUT) {
      return cart;
    }

    // Seller-only routes
    if (route == AppRoutes.SELLER_DASHBOARD ||
        route == AppRoutes.SELLER_PRODUCTS ||
        route == AppRoutes.SELLER_ADD_PRODUCT ||
        route == AppRoutes.SELLER_ORDERS) {
      return sellerPanel;
    }

    // Appointments
    if (route.startsWith('/appointments')) {
      return appointments;
    }

    // Community
    if (route == AppRoutes.COMMUNITY || route.startsWith('/community')) {
      return community;
    }

    // Weather
    if (route == AppRoutes.WEATHER) {
      return weather;
    }

    // Chatbot
    if (route == AppRoutes.CHATBOT) {
      return chatbot;
    }

    // Crop Tracker
    if (route == AppRoutes.CROP_TRACKER) {
      return cropTracker;
    }

    // Crop Recommendation
    if (route == AppRoutes.CROP_RECOMMENDATION ||
        route == AppRoutes.CROP_RECOMMENDATION_RESULTS ||
        route == AppRoutes.CROP_RECOMMENDATION_HISTORY) {
      return cropRecommendation;
    }

    // No restriction for auth, home, profile, onboarding routes
    return null;
  }

  // ═══════════════════════════════════════════
  //  GUARD + REDIRECT HELPER
  // ═══════════════════════════════════════════

  /// Check access for a route and redirect if unauthorized.
  /// Returns true if access is allowed, false if redirected.
  static bool guardRoute(String route) {
    final module = moduleForRoute(route);
    if (module == null) return true; // Unrestricted route

    if (currentUserCanAccess(module)) return true;

    debugPrint(
      '[RoleGuard] ❌ $currentUserType blocked from $route (module: $module)',
    );
    AppSnackbar.warning('You do not have access to this feature.');
    Get.offAllNamed(currentDefaultRoute);
    return false;
  }

  // ═══════════════════════════════════════════
  //  NAVIGATION UI HELPERS
  // ═══════════════════════════════════════════

  /// Get the list of feature cards to show on home screen for the current role
  static List<String> get allowedFeatures {
    final type = currentUserType;
    final allowed = _accessMatrix[type] ?? {};
    final features = <String>[];

    if (allowed.contains(appointments)) features.add('appointments');
    if (allowed.contains(marketplace) || allowed.contains(sellerPanel)) {
      features.add('marketplace');
    }
    if (allowed.contains(weather)) features.add('weather');
    if (allowed.contains(cropTracker)) features.add('crop_tracker');
    if (allowed.contains(cropRecommendation)) {
      features.add('crop_recommendation');
    }
    if (allowed.contains(community)) features.add('community');
    if (allowed.contains(chatbot)) features.add('chatbot');

    return features;
  }

  /// Get the bottom navigation items for the current role.
  /// Returns a list of tab identifiers: 'home', 'marketplace', 'weather',
  /// 'crop_tracker', 'community', 'appointments'.
  static List<String> get bottomNavTabs {
    final type = currentUserType;
    final allowed = _accessMatrix[type] ?? {};
    final tabs = <String>['home']; // Home is always first

    if (type == 'company') {
      tabs.add('marketplace'); // Shows seller dashboard
    } else if (type == 'expert') {
      tabs.add('appointments');
      tabs.add('community');
    } else {
      // Farmer / guest — full nav
      tabs.add('marketplace');
      tabs.add('weather');
      if (allowed.contains(cropTracker)) tabs.add('crop_tracker');
      tabs.add('community');
    }

    return tabs;
  }
}
