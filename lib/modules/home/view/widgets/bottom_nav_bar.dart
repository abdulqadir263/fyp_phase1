import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../view_model/home_controller.dart';

/// Custom bottom navigation bar widget
class CustomBottomNavBar extends GetView<HomeController> {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: _handleNavTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppConstants.primaryGreen,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 0,
            backgroundColor: Colors.transparent,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bug_report_outlined),
                activeIcon: Icon(Icons.bug_report),
                label: 'Diagnosis',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Market',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    switch (index) {
      case 0:
      // Stay on home
        controller.changePage(0);
        break;
      case 1:
      // Navigate to disease detection
        Get.toNamed(AppRoutes.DISEASE_DETECTION);
        break;
      case 2:
      // Navigate to community
        Get.toNamed(AppRoutes.COMMUNITY);
        break;
      case 3:
      // Navigate to marketplace
        Get.toNamed(AppRoutes.MARKETPLACE);
        break;
      case 4:
      // Navigate to profile
        controller.goToProfile();
        break;
    }
  }
}
