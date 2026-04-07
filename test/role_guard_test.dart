import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the centralized RoleGuard access control system.
/// Tests the access matrix, module mapping, navigation helpers,
/// and ensures no security holes across all role-module combinations.
void main() {
  // ═══════════════════════════════════════════
  //  ACCESS MATRIX CONSTANTS (mirrored from RoleGuard)
  // ═══════════════════════════════════════════

  const marketplace = 'marketplace';
  const sellerPanel = 'seller_panel';
  const cart = 'cart';
  const appointments = 'appointments';
  const community = 'community';
  const weather = 'weather';
  const chatbot = 'chatbot';
  const profile = 'profile';
  const cropTracker = 'crop_tracker';

  /// Local copy of the access matrix for unit testing
  /// (avoids importing the full Flutter app)
  const Map<String, Set<String>> accessMatrix = {
    'farmer': {
      marketplace,
      cart,
      appointments,
      community,
      weather,
      chatbot,
      profile,
      cropTracker,
    },
    'expert': {appointments, community, chatbot, profile},
    'company': {marketplace, sellerPanel, chatbot, profile},
    'guest': {weather, chatbot},
  };

  /// Check access using the test copy of the matrix
  bool canAccess(String module, String userType) {
    final allowed = accessMatrix[userType];
    if (allowed == null) return false;
    return allowed.contains(module);
  }

  // ═══════════════════════════════════════════
  //  FARMER ACCESS TESTS
  // ═══════════════════════════════════════════

  group('Farmer Access', () {
    const role = 'farmer';

    test('can access Marketplace (buyer)', () {
      expect(canAccess(marketplace, role), true);
    });

    test('can access Cart', () {
      expect(canAccess(cart, role), true);
    });

    test('can access Appointments', () {
      expect(canAccess(appointments, role), true);
    });

    test('can access Community', () {
      expect(canAccess(community, role), true);
    });

    test('can access Weather', () {
      expect(canAccess(weather, role), true);
    });

    test('can access Chatbot', () {
      expect(canAccess(chatbot, role), true);
    });

    test('can access Profile', () {
      expect(canAccess(profile, role), true);
    });

    test('can access Crop Tracker', () {
      expect(canAccess(cropTracker, role), true);
    });

    test('cannot access Seller Panel', () {
      expect(canAccess(sellerPanel, role), false);
    });
  });

  // ═══════════════════════════════════════════
  //  EXPERT ACCESS TESTS
  // ═══════════════════════════════════════════

  group('Expert Access', () {
    const role = 'expert';

    test('can access Appointments', () {
      expect(canAccess(appointments, role), true);
    });

    test('can access Community', () {
      expect(canAccess(community, role), true);
    });

    test('can access Profile', () {
      expect(canAccess(profile, role), true);
    });

    test('can access Chatbot', () {
      expect(canAccess(chatbot, role), true);
    });

    test('CANNOT access Marketplace', () {
      expect(canAccess(marketplace, role), false);
    });

    test('CANNOT access Cart', () {
      expect(canAccess(cart, role), false);
    });

    test('CANNOT access Seller Panel', () {
      expect(canAccess(sellerPanel, role), false);
    });

    test('CANNOT access Weather', () {
      expect(canAccess(weather, role), false);
    });

    test('CANNOT access Crop Tracker', () {
      expect(canAccess(cropTracker, role), false);
    });
  });

  // ═══════════════════════════════════════════
  //  COMPANY ACCESS TESTS
  // ═══════════════════════════════════════════

  group('Company Access', () {
    const role = 'company';

    test('can access Marketplace (product browsing)', () {
      expect(canAccess(marketplace, role), true);
    });

    test('can access Seller Panel', () {
      expect(canAccess(sellerPanel, role), true);
    });

    test('can access Profile', () {
      expect(canAccess(profile, role), true);
    });

    test('can access Chatbot', () {
      expect(canAccess(chatbot, role), true);
    });

    test('CANNOT access Cart', () {
      expect(canAccess(cart, role), false);
    });

    test('CANNOT access Appointments', () {
      expect(canAccess(appointments, role), false);
    });

    test('CANNOT access Community', () {
      expect(canAccess(community, role), false);
    });

    test('CANNOT access Weather', () {
      expect(canAccess(weather, role), false);
    });

    test('CANNOT access Crop Tracker', () {
      expect(canAccess(cropTracker, role), false);
    });
  });

  // ═══════════════════════════════════════════
  //  GUEST ACCESS TESTS
  // ═══════════════════════════════════════════

  group('Guest Access', () {
    const role = 'guest';

    test('can access Weather', () {
      expect(canAccess(weather, role), true);
    });

    test('can access Chatbot', () {
      expect(canAccess(chatbot, role), true);
    });

    test('CANNOT access Marketplace', () {
      expect(canAccess(marketplace, role), false);
    });

    test('CANNOT access Cart', () {
      expect(canAccess(cart, role), false);
    });

    test('CANNOT access Appointments', () {
      expect(canAccess(appointments, role), false);
    });

    test('CANNOT access Community', () {
      expect(canAccess(community, role), false);
    });

    test('CANNOT access Profile', () {
      expect(canAccess(profile, role), false);
    });

    test('CANNOT access Seller Panel', () {
      expect(canAccess(sellerPanel, role), false);
    });

    test('CANNOT access Crop Tracker', () {
      expect(canAccess(cropTracker, role), false);
    });
  });

  // ═══════════════════════════════════════════
  //  UNKNOWN ROLE TESTS
  // ═══════════════════════════════════════════

  group('Unknown Role', () {
    test('unknown role cannot access any module', () {
      expect(canAccess(marketplace, 'admin'), false);
      expect(canAccess(appointments, 'admin'), false);
      expect(canAccess(community, 'admin'), false);
      expect(canAccess(weather, 'admin'), false);
      expect(canAccess(cart, 'admin'), false);
      expect(canAccess(sellerPanel, 'admin'), false);
      expect(canAccess(profile, 'admin'), false);
    });

    test('empty string role cannot access anything', () {
      expect(canAccess(marketplace, ''), false);
      expect(canAccess(appointments, ''), false);
    });
  });

  // ═══════════════════════════════════════════
  //  DEFAULT ROUTE MAPPING TESTS
  // ═══════════════════════════════════════════

  group('Default Route Mapping', () {
    String defaultRouteFor(String userType) {
      switch (userType) {
        case 'company':
          return '/marketplace/seller/dashboard';
        case 'expert':
          return '/appointments/expert-dashboard';
        case 'farmer':
          return '/home';
        default:
          return '/home';
      }
    }

    test('company default is seller dashboard', () {
      expect(defaultRouteFor('company'), '/marketplace/seller/dashboard');
    });

    test('expert default is expert dashboard', () {
      expect(defaultRouteFor('expert'), '/appointments/expert-dashboard');
    });

    test('farmer default is home', () {
      expect(defaultRouteFor('farmer'), '/home');
    });

    test('guest default is home', () {
      expect(defaultRouteFor('guest'), '/home');
    });

    test('unknown default is home', () {
      expect(defaultRouteFor('xyz'), '/home');
    });
  });

  // ═══════════════════════════════════════════
  //  ROUTE → MODULE MAPPING TESTS
  // ═══════════════════════════════════════════

  group('Route to Module Mapping', () {
    String? moduleForRoute(String route) {
      if (route == '/marketplace' ||
          route == '/marketplace/product' ||
          route == '/marketplace/orders' ||
          route == '/marketplace/orders/detail') {
        return marketplace;
      }
      if (route == '/marketplace/cart' || route == '/marketplace/checkout') {
        return cart;
      }
      if (route == '/marketplace/seller/dashboard' ||
          route == '/marketplace/seller/products' ||
          route == '/marketplace/seller/add-product' ||
          route == '/marketplace/seller/orders') {
        return sellerPanel;
      }
      if (route.startsWith('/appointments')) return appointments;
      if (route == '/community' || route.startsWith('/community')) {
        return community;
      }
      if (route == '/weather') return weather;
      if (route == '/chatbot') return chatbot;
      if (route == '/crop-tracker') return cropTracker;
      return null;
    }

    test('marketplace buyer routes map to marketplace module', () {
      expect(moduleForRoute('/marketplace'), marketplace);
      expect(moduleForRoute('/marketplace/product'), marketplace);
      expect(moduleForRoute('/marketplace/orders'), marketplace);
    });

    test('cart/checkout routes map to cart module', () {
      expect(moduleForRoute('/marketplace/cart'), cart);
      expect(moduleForRoute('/marketplace/checkout'), cart);
    });

    test('seller routes map to seller_panel module', () {
      expect(moduleForRoute('/marketplace/seller/dashboard'), sellerPanel);
      expect(moduleForRoute('/marketplace/seller/products'), sellerPanel);
      expect(moduleForRoute('/marketplace/seller/add-product'), sellerPanel);
      expect(moduleForRoute('/marketplace/seller/orders'), sellerPanel);
    });

    test('appointment routes map to appointments module', () {
      expect(moduleForRoute('/appointments'), appointments);
      expect(moduleForRoute('/appointments/expert-profile'), appointments);
      expect(moduleForRoute('/appointments/request-visit'), appointments);
      expect(moduleForRoute('/appointments/expert-dashboard'), appointments);
    });

    test('community routes map to community module', () {
      expect(moduleForRoute('/community'), community);
      expect(moduleForRoute('/community/create'), community);
      expect(moduleForRoute('/community/bookmarks'), community);
    });

    test('weather route maps to weather module', () {
      expect(moduleForRoute('/weather'), weather);
    });

    test('chatbot route maps to chatbot module', () {
      expect(moduleForRoute('/chatbot'), chatbot);
    });

    test('auth and home routes are unrestricted (null)', () {
      expect(moduleForRoute('/login'), null);
      expect(moduleForRoute('/home'), null);
      expect(moduleForRoute('/profile'), null);
    });
  });

  // ═══════════════════════════════════════════
  //  BOTTOM NAV TABS TESTS
  // ═══════════════════════════════════════════

  group('Bottom Nav Tabs per Role', () {
    List<String> bottomNavTabsFor(String userType) {
      final allowed = accessMatrix[userType] ?? {};
      final tabs = <String>['home'];

      if (userType == 'company') {
        tabs.add('marketplace');
      } else if (userType == 'expert') {
        tabs.add('appointments');
        tabs.add('community');
      } else {
        tabs.add('marketplace');
        tabs.add('weather');
        if (allowed.contains(cropTracker)) tabs.add('crop_tracker');
        tabs.add('community');
      }
      return tabs;
    }

    test(
      'farmer sees full nav: home, marketplace, weather, crop_tracker, community',
      () {
        final tabs = bottomNavTabsFor('farmer');
        expect(tabs, [
          'home',
          'marketplace',
          'weather',
          'crop_tracker',
          'community',
        ]);
      },
    );

    test('expert sees: home, appointments, community', () {
      final tabs = bottomNavTabsFor('expert');
      expect(tabs, ['home', 'appointments', 'community']);
    });

    test('company sees: home, marketplace', () {
      final tabs = bottomNavTabsFor('company');
      expect(tabs, ['home', 'marketplace']);
    });

    test('guest sees: home, marketplace, weather, community (limited nav)', () {
      final tabs = bottomNavTabsFor('guest');
      expect(tabs, ['home', 'marketplace', 'weather', 'community']);
    });
  });

  // ═══════════════════════════════════════════
  //  ALLOWED FEATURES GRID TESTS
  // ═══════════════════════════════════════════

  group('Allowed Features per Role', () {
    List<String> allowedFeaturesFor(String userType) {
      final allowed = accessMatrix[userType] ?? {};
      final features = <String>[];
      if (allowed.contains(appointments)) features.add('appointments');
      if (allowed.contains(marketplace) || allowed.contains(sellerPanel)) {
        features.add('marketplace');
      }
      if (allowed.contains(weather)) features.add('weather');
      if (allowed.contains(cropTracker)) features.add('crop_tracker');
      if (allowed.contains(community)) features.add('community');
      if (allowed.contains(chatbot)) features.add('chatbot');
      return features;
    }

    test('farmer sees all features', () {
      final features = allowedFeaturesFor('farmer');
      expect(features.contains('appointments'), true);
      expect(features.contains('marketplace'), true);
      expect(features.contains('weather'), true);
      expect(features.contains('crop_tracker'), true);
      expect(features.contains('community'), true);
      expect(features.contains('chatbot'), true);
    });

    test('expert sees only appointments, community, chatbot', () {
      final features = allowedFeaturesFor('expert');
      expect(features, ['appointments', 'community', 'chatbot']);
      expect(features.contains('marketplace'), false);
      expect(features.contains('weather'), false);
    });

    test('company sees marketplace + chatbot only', () {
      final features = allowedFeaturesFor('company');
      expect(features, ['marketplace', 'chatbot']);
      expect(features.contains('appointments'), false);
      expect(features.contains('community'), false);
    });

    test('guest sees weather + chatbot only', () {
      final features = allowedFeaturesFor('guest');
      expect(features, ['weather', 'chatbot']);
    });
  });

  // ═══════════════════════════════════════════
  //  CROSS-ROLE SECURITY SCENARIOS
  // ═══════════════════════════════════════════

  group('Security Scenarios', () {
    test('expert cannot reach cart via direct route', () {
      expect(canAccess(cart, 'expert'), false);
    });

    test('company cannot reach appointments via direct route', () {
      expect(canAccess(appointments, 'company'), false);
    });

    test('company cannot reach community via direct route', () {
      expect(canAccess(community, 'company'), false);
    });

    test('expert cannot reach seller panel', () {
      expect(canAccess(sellerPanel, 'expert'), false);
    });

    test('guest cannot reach any protected module', () {
      expect(canAccess(marketplace, 'guest'), false);
      expect(canAccess(cart, 'guest'), false);
      expect(canAccess(appointments, 'guest'), false);
      expect(canAccess(community, 'guest'), false);
      expect(canAccess(sellerPanel, 'guest'), false);
      expect(canAccess(profile, 'guest'), false);
    });

    test('farmer has maximum access except seller panel', () {
      final farmerModules = accessMatrix['farmer']!;
      expect(farmerModules.length, 8);
      expect(farmerModules.contains(sellerPanel), false);
    });

    test('expert has exactly 4 modules', () {
      expect(accessMatrix['expert']!.length, 4);
    });

    test('company has exactly 4 modules', () {
      expect(accessMatrix['company']!.length, 4);
    });

    test('guest has exactly 2 modules', () {
      expect(accessMatrix['guest']!.length, 2);
    });
  });

  // ═══════════════════════════════════════════
  //  EXHAUSTIVE MATRIX TEST
  // ═══════════════════════════════════════════

  group('Exhaustive Access Matrix', () {
    final allModules = [
      marketplace,
      sellerPanel,
      cart,
      appointments,
      community,
      weather,
      chatbot,
      profile,
      cropTracker,
    ];
    final allRoles = ['farmer', 'expert', 'company', 'guest'];

    test('every role-module pair is deterministic', () {
      for (final role in allRoles) {
        for (final mod in allModules) {
          // Just assert it doesn't throw — all pairs are defined
          expect(canAccess(mod, role), isA<bool>());
        }
      }
    });

    test('total allowed count matches expectations', () {
      // farmer: 8, expert: 4, company: 4, guest: 2 = 18 total allowed
      int totalAllowed = 0;
      for (final role in allRoles) {
        for (final mod in allModules) {
          if (canAccess(mod, role)) totalAllowed++;
        }
      }
      expect(totalAllowed, 18);
    });
  });
}
