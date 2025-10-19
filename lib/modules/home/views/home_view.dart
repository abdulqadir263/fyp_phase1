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
        title: const Text('FarmAssist'),
        centerTitle: true,
        actions: [
          // Language toggle button
          IconButton(
            icon: const Icon(Icons.language),
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
          _buildHomeContent(context), // Home tab content
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
          // Drawer Header with guest user handling
          Obx(() {
            final userName = controller.user.value?.name ?? 'Guest User';
            final userEmail =
                controller.user.value?.email ?? 'guest@example.com';
            final isGuest = controller.isGuestUser;
            final profileImageUrl = controller.user.value?.profileImage ?? '';

            return UserAccountsDrawerHeader(
              accountName: Text(
                userName,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              accountEmail: Text(
                userEmail,
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                // ✅ FIX: Profile image ko behtar tareeqe se handle karna
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl.isEmpty
                    ? Icon(
                  isGuest ? Icons.person_outline : Icons.person,
                  size: 40,
                  color: Colors.grey[600],
                )
                    : null,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            );
          }),

          // Drawer items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Get.back(); // Drawer close karo
              controller.changePage(0); // Home tab select karo
            },
          ),

          // Profile tile with guest handling
          Obx(() => ListTile(
            leading: const Icon(Icons.person),
            title:
            Text(controller.isGuestUser ? 'Create Account' : 'Profile'),
            onTap: () {
              Get.back(); // Drawer close karo
              if (controller.isGuestUser) {
                Get.offAllNamed(AppRoutes.LOGIN); // Go to login to sign up
              } else {
                controller.goToProfile();
              }
            },
          )),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Get.back(); // Drawer close karo
              controller.goToSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Get.back(); // Drawer close karo
              controller.goToAbout();
            },
          ),
          const Divider(),

          // Logout/Login-As-Guest tile
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
      items: const [
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
  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Message for guest
          Obx(() => Text(
            controller.welcomeMessage,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )),

          // Guest user banner
          Obx(() => controller.isGuestUser
              ? Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are browsing as a guest. Some features may be limited.',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          )
              : const SizedBox.shrink()),

          // Profile incomplete banner
          Obx(() => controller.isProfileIncomplete && !controller.isGuestUser
              ? Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              border: Border.all(color: Colors.blue.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade800),
                const SizedBox(width: 8),
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
                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
              : const SizedBox.shrink()),

          Text(
            'What would you like to do today?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // ✅ UPDATED: Responsive Feature Cards Grid
          _buildResponsiveFeatureGrid(context),
        ],
      ),
    );
  }

  // ✅ NEW: Responsive Grid build karna
  Widget _buildResponsiveFeatureGrid(BuildContext context) {
    // Screen ki width hasil karna
    final screenWidth = MediaQuery.of(context).size.width;

    // Screen ki width ke hisab se columns set karna
    int crossAxisCount = 2;
    if (screenWidth > 1200) {
      crossAxisCount = 4; // Bari screens (web)
    } else if (screenWidth > 600) {
      crossAxisCount = 3; // Darmiyani screens (tablet)
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1, // Card ki height/width ratio
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
    );
  }

  // Feature Card widget
  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    // LayoutBuilder card ke size ke hisab se UI adjust karta hai
    return LayoutBuilder(
      builder: (context, constraints) {
        // Card ke size ke hisab se icon aur font size adjust karna
        final double iconSize = constraints.maxWidth * 0.3;
        final double fontSize = constraints.maxWidth * 0.1;

        return CustomCard(
          onTap: onTap,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(constraints.maxWidth * 0.1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize > 16 ? 16 : fontSize, // Max font size 16
                  fontWeight: FontWeight.w600,
                ),
                // ✅ FIX: Overflow error ko theek karna
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }

  // Placeholder content for other tabs
  Widget _buildMarketplaceContent() {
    return const Center(
      child: Text('Marketplace Content - Coming Soon!'),
    );
  }

  Widget _buildWeatherContent() {
    return const Center(
      child: Text('Weather Content - Coming Soon!'),
    );
  }

  Widget _buildCropTrackerContent() {
    return const Center(
      child: Text('Crop Tracker Content - Coming Soon!'),
    );
  }

  Widget _buildCommunityContent() {
    return const Center(
      child: Text('Community Content - Coming Soon!'),
    );
  }
}