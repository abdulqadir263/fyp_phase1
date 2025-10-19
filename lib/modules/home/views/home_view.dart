import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/home_controller.dart';
import '../../../app/widgets/custom_card.dart';

// Home screen ka UI
class HomeView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App Bar
      appBar: AppBar(
        title: Text('FarmAssist'),
        centerTitle: true,
        actions: [
          // Language toggle button
          IconButton(
            icon: Icon(Icons.language),
            onPressed: controller.toggleLanguage,
            tooltip: 'Change Language',
          ),
        ],
      ),

      // Side Drawer
      drawer: _buildDrawer(context),

      // Body
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: [
          _buildHomeContent(), // Home tab content
          _buildMarketplaceContent(), // Marketplace tab content
          _buildWeatherContent(), // Weather tab content
          _buildCropTrackerContent(), // Crop Tracker tab content
          _buildCommunityContent(), // Community tab content
        ],
      )),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Drawer build karna
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ✅ UPDATED: Drawer Header with guest user handling
          Obx(() {
            final userName = controller.user.value?.name ?? 'Guest User';
            final userEmail = controller.user.value?.email ?? 'guest@example.com';
            final isGuest = controller.isGuestUser;

            return UserAccountsDrawerHeader(
              accountName: Text(
                userName,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              accountEmail: Text(
                userEmail,
                style: TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: isGuest
                    ? Icon(Icons.person_outline, size: 40, color: Colors.grey)
                    : Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            );
          }),

          // Drawer items
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Get.back(); // Drawer close karo
              controller.changePage(0); // Home tab select karo
            },
          ),

          // ✅ UPDATED: Profile tile with guest handling
          Obx(() => ListTile(
            leading: Icon(Icons.person),
            title: Text(controller.isGuestUser ? 'Create Account' : 'Profile'),
            onTap: () {
              Get.back(); // Drawer close karo
              if (controller.isGuestUser) {
                Get.offAllNamed(AppRoutes.LOGIN); // Go to login to sign up
              } else {
                controller.goToProfile();
              }
            },
          )),

          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Get.back(); // Drawer close karo
              controller.goToSettings();
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {
              Get.back(); // Drawer close karo
              controller.goToAbout();
            },
          ),
          Divider(),

          // ✅ UPDATED: Logout/Login-As-Guest tile
          Obx(() => ListTile(
            leading: Icon(
              controller.isGuestUser ? Icons.login : Icons.logout,
              color: controller.isGuestUser ? Colors.green : Colors.red,
            ),
            title: Text(
              controller.isGuestUser ? 'Login / Sign Up' : 'Logout',
              style: TextStyle(
                color: controller.isGuestUser ? Colors.green : Colors.red,
              ),
            ),
            onTap: () {
              Get.back(); // Drawer close karo
              if (controller.isGuestUser) {
                Get.offAllNamed(AppRoutes.LOGIN);
              } else {
                controller.logout();
              }
            },
          )),
        ],
      ),
    );
  }

  // Bottom Navigation Bar build karna
  Widget _buildBottomNavigationBar() {
    return Obx(() => BottomNavigationBar(
      currentIndex: controller.currentIndex.value,
      onTap: controller.changePage,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(Get.context!).primaryColor,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Marketplace',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud),
          label: 'Weather',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.agriculture),
          label: 'Crop Tracker',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Community',
        ),
      ],
    ));
  }

  // Home tab content
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ UPDATED: Welcome Message for guest
          Obx(() => Text(
            controller.welcomeMessage,
            style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )),

          // ✅ NEW: Guest user banner
          Obx(() => controller.isGuestUser
              ? Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade800),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are browsing as a guest. Some features may be limited.',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          )
              : SizedBox.shrink()),

          // ✅ NEW: Profile incomplete banner
          Obx(() => controller.isProfileIncomplete && !controller.isGuestUser
              ? Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              border: Border.all(color: Colors.blue.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade800),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your profile is incomplete. Please complete your profile to access all features.',
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ),
                TextButton(
                  onPressed: () => controller.goToProfile(),
                  child: Text(
                    'Complete Now',
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          )
              : SizedBox.shrink()),

          SizedBox(height: 8),
          Text(
            'What would you like to do today?',
            style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),

          // ✅ UPDATED: Feature Cards Grid
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildFeatureCard(
                title: 'Book Appointment',
                icon: Icons.calendar_today,
                color: Colors.blue,
                onTap: () => controller.navigateToFeature('appointments'),
              ),
              _buildFeatureCard(
                title: 'Marketplace',
                icon: Icons.shopping_cart,
                color: Colors.green,
                onTap: () => controller.navigateToFeature('marketplace'),
              ),
              _buildFeatureCard(
                title: 'Weather Advice',
                icon: Icons.cloud,
                color: Colors.orange,
                onTap: () => controller.navigateToFeature('weather'),
              ),
              _buildFeatureCard(
                title: 'Crop Tracker',
                icon: Icons.agriculture,
                color: Colors.brown,
                onTap: () => controller.navigateToFeature('crop_tracker'),
              ),
              _buildFeatureCard(
                title: 'Community',
                icon: Icons.people,
                color: Colors.purple,
                onTap: () => controller.navigateToFeature('community'),
              ),
              _buildFeatureCard(
                title: 'Agri Chatbot',
                icon: Icons.chat,
                color: Colors.teal,
                onTap: () => controller.navigateToFeature('chatbot'),
              ),
              _buildFeatureCard(
                title: 'Disease Detection',
                icon: Icons.bug_report,
                color: Colors.red,
                onTap: () => controller.navigateToFeature('disease_detection'),
              ),
              _buildFeatureCard(
                title: 'Crop Recommendation',
                icon: Icons.eco,
                color: Colors.lightGreen,
                onTap: () => controller.navigateToFeature('crop_recommendation'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Feature Card widget
  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: color,
            ),
          ),
          SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder content for other tabs
  Widget _buildMarketplaceContent() {
    return Center(
      child: Text('Marketplace Content - Coming Soon!'),
    );
  }

  Widget _buildWeatherContent() {
    return Center(
      child: Text('Weather Content - Coming Soon!'),
    );
  }

  Widget _buildCropTrackerContent() {
    return Center(
      child: Text('Crop Tracker Content - Coming Soon!'),
    );
  }

  Widget _buildCommunityContent() {
    return Center(
      child: Text('Community Content - Coming Soon!'),
    );
  }
}