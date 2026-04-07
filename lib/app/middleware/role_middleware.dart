import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../core/utils/role_guard.dart';

/// GetX middleware that checks role permissions before navigating to any route.
/// If the user's role lacks access, they are redirected to their default module.
class RoleMiddleware extends GetMiddleware {
  @override
  int? get priority => 1; // Run early

  @override
  RouteSettings? redirect(String? route) {
    if (route == null) return null;

    final module = RoleGuard.moduleForRoute(route);
    if (module == null) return null; // Unrestricted route

    if (RoleGuard.currentUserCanAccess(module)) {
      return null; // Allowed — proceed normally
    }

    // Blocked — redirect to role's default screen
    final redirectTo = RoleGuard.currentDefaultRoute;
    debugPrint(
      '[RoleMiddleware] ❌ ${RoleGuard.currentUserType} blocked from $route → redirecting to $redirectTo',
    );
    return RouteSettings(name: redirectTo);
  }
}
