import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp_phase1/modules/appointments/view/appointment_detail_view.dart';
import 'package:fyp_phase1/modules/home/view/home_view.dart';
import 'package:get/get.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../app/routes/app_routes.dart';
import '../../app/utils/app_snackbar.dart';

// Module view imports — IndexedStack ke liye embedded widgets
import '../../modules/marketplace/view/marketplace_view.dart';
import '../../modules/marketplace/view/seller_dashboard_view.dart';
import '../../modules/community/view/community_view.dart';
import '../../modules/appointments/view/appointments_view.dart';
import '../../modules/weather/view/weather_view.dart';
import '../../modules/crop_tracker/view/crop_tracker_view.dart';

class RoleGuard {
  RoleGuard._();

  static const String marketplace        = 'marketplace';
  static const String sellerPanel        = 'seller_panel';
  static const String cart               = 'cart';
  static const String appointments       = 'appointments';
  static const String community          = 'community';
  static const String weather            = 'weather';
  static const String chatbot            = 'chatbot';
  static const String profile            = 'profile';
  static const String cropTracker        = 'crop_tracker';
  static const String cropRecommendation = 'crop_recommendation';

  static const Map<String, Set<String>> _accessMatrix = {
    'farmer': {
      marketplace, cart, appointments, community,
      weather, chatbot, profile, cropTracker, cropRecommendation,
    },
    'expert':  {appointments, community, profile},
    'company': {marketplace, sellerPanel, profile},
    'guest':   {weather, chatbot},
  };

  static bool canAccess(String module, String userType) =>
      _accessMatrix[userType]?.contains(module) ?? false;

  static String get currentUserType {
    try {
      return Get.find<AuthRepository>().currentUser.value?.userType ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  static bool currentUserCanAccess(String module) =>
      canAccess(module, currentUserType);

  static String defaultRouteFor(String userType) {
    switch (userType) {
      case 'company': return AppRoutes.SELLER_DASHBOARD;
      case 'expert':  return AppRoutes.HOME;
      default:        return AppRoutes.HOME;
    }
  }

  static String get currentDefaultRoute => defaultRouteFor(currentUserType);

  static String? moduleForRoute(String route) {
    if (route == AppRoutes.MARKETPLACE ||
        route == AppRoutes.MARKETPLACE_PRODUCT ||
        route == AppRoutes.ORDER_HISTORY ||
        route == AppRoutes.ORDER_DETAIL) return marketplace;

    if (route == AppRoutes.MARKETPLACE_CART ||
        route == AppRoutes.MARKETPLACE_CHECKOUT) return cart;

    if (route == AppRoutes.SELLER_DASHBOARD ||
        route == AppRoutes.SELLER_PRODUCTS ||
        route == AppRoutes.SELLER_ADD_PRODUCT ||
        route == AppRoutes.SELLER_ORDERS) return sellerPanel;

    if (route.startsWith('/appointments')) return appointments;
    if (route == AppRoutes.COMMUNITY ||
        route.startsWith('/community')) return community;
    if (route == AppRoutes.WEATHER) return weather;
    if (route == AppRoutes.CHATBOT) return chatbot;
    if (route == AppRoutes.CROP_TRACKER) return cropTracker;
    if (route == AppRoutes.CROP_RECOMMENDATION ||
        route == AppRoutes.CROP_RECOMMENDATION_RESULTS ||
        route == AppRoutes.CROP_RECOMMENDATION_HISTORY) return cropRecommendation;

    return null;
  }

  static bool guardRoute(String route) {
    final module = moduleForRoute(route);
    if (module == null) return true;
    if (currentUserCanAccess(module)) return true;

    debugPrint('[RoleGuard] $currentUserType blocked from $route');
    AppSnackbar.warning('You do not have access to this feature.');
    Get.offAllNamed(currentDefaultRoute);
    return false;
  }

  static List<String> get allowedFeatures {
    final allowed = _accessMatrix[currentUserType] ?? {};
    final features = <String>[];
    if (allowed.contains(appointments)) features.add('appointments');
    if (allowed.contains(marketplace) || allowed.contains(sellerPanel)) {
      features.add('marketplace');
    }
    if (allowed.contains(weather)) features.add('weather');
    if (allowed.contains(cropTracker)) features.add('crop_tracker');
    if (allowed.contains(cropRecommendation)) features.add('crop_recommendation');
    if (allowed.contains(community)) features.add('community');
    if (allowed.contains(chatbot)) features.add('chatbot');
    return features;
  }

  static List<String> get bottomNavTabs {
    final type = currentUserType;
    final tabs = <String>['home'];

    if (type == 'company') {
      tabs.add('marketplace');
    } else if (type == 'expert') {
      tabs.add('appointments');
      tabs.add('community');
    } else {
      // farmer (and any other role)
      tabs.add('marketplace');
      tabs.add('appointments');
      tabs.add('community');
    }
    return tabs;
  }

  // IndexedStack ke liye — actual embedded widgets return karta hai
  // Get.toNamed() nahi — tab switch pe widget rebuild nahi hota
  static Widget contentForTab(String tab, BuildContext context) {
    switch (tab) {
      case 'home':
        return const HomeView();
      case 'marketplace':
        return currentUserType == 'company'
            ? const SellerDashboardView()
            : const MarketplaceHomeView();
      case 'community':
        return const CommunityView();
      case 'appointments':
        return const AppointmentDetailView();
      default:
        return _buildPlaceholder(tab);
    }
  }

  static Widget _buildPlaceholder(String tab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(tab,
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('Coming soon',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }
}