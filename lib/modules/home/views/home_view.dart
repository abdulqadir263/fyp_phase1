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
        title: const Text('Aasaan Kisaan'),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
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
                  margin: EdgeInsets.symmetric(vertical: isLargeScreen ? 20 : 16),
                  padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    border: Border.all(color: Colors.orange.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800),
                      SizedBox(width: isLargeScreen ? 12 : 8),
                      Expanded(
                        child: Text(
                          'You are browsing as a guest. Some features may be limited.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: isLargeScreen ? 16 : 14,
                          ),
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
                  margin: EdgeInsets.only(bottom: isLargeScreen ? 20 : 16),
                  padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    border: Border.all(color: Colors.blue.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade800),
                      SizedBox(width: isLargeScreen ? 12 : 8),
                      Expanded(
                        child: Text(
                          'Your profile is incomplete. Please complete your profile to access all features.',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: isLargeScreen ? 16 : 14,
                          ),
                        ),
                      ),
                      if (isLargeScreen) ...[
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => controller.goToProfile(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Complete Now'),
                        ),
                      ] else ...[
                        TextButton(
                          onPressed: () => controller.goToProfile(),
                          child: Text(
                            'Complete Now',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
                    : const SizedBox.shrink()),

                SizedBox(height: isLargeScreen ? 8 : 4),

                Text(
                  'What would you like to do today?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isLargeScreen ? 18 : 16,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 32 : 24),

                // ✅ UPDATED: Responsive Feature Cards Grid
                _buildResponsiveFeatureGrid(context),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ IMPROVED: Responsive Grid build karna
  Widget _buildResponsiveFeatureGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Screen ki width ke hisab se columns set karna
        int crossAxisCount;
        double childAspectRatio;
        double crossAxisSpacing;
        double mainAxisSpacing;

        if (screenWidth > 1200) {
          // Large desktop screens
          crossAxisCount = 4;
          childAspectRatio = 1.0;
          crossAxisSpacing = 24;
          mainAxisSpacing = 24;
        } else if (screenWidth > 800) {
          // Tablets and small desktop
          crossAxisCount = 3;
          childAspectRatio = 1.0;
          crossAxisSpacing = 20;
          mainAxisSpacing = 20;
        } else if (screenWidth > 600) {
          // Large mobile devices
          crossAxisCount = 3;
          childAspectRatio = 1.0;
          crossAxisSpacing = 16;
          mainAxisSpacing = 16;
        } else if (screenWidth > 400) {
          // Medium mobile devices
          crossAxisCount = 2;
          childAspectRatio = 1.1;
          crossAxisSpacing = 12;
          mainAxisSpacing = 12;
        } else {
          // Small mobile devices
          crossAxisCount = 2;
          childAspectRatio = 0.9;
          crossAxisSpacing = 8;
          mainAxisSpacing = 8;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
          padding: EdgeInsets.zero,
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
      },
    );
  }

  // ✅ IMPROVED: Feature Card widget with better responsiveness
  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;
        final double cardHeight = constraints.maxHeight;

        // Card size ke hisab se icon aur font size adjust karna
        final double iconSize = cardWidth * 0.25;
        final double fontSize = cardWidth * 0.09;

        // Minimum and maximum sizes set karna
        final double finalIconSize = iconSize.clamp(24.0, 40.0);
        final double finalFontSize = fontSize.clamp(12.0, 16.0);

        return CustomCard(
          onTap: onTap,
          padding: EdgeInsets.all(cardWidth * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: EdgeInsets.all(cardWidth * 0.08),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: finalIconSize,
                  color: color,
                ),
              ),

              // Spacer with dynamic height
              SizedBox(height: cardHeight * 0.05),

              // Title Text
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: finalFontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ IMPROVED: Placeholder content for other tabs with responsive design
  Widget _buildMarketplaceContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;

        return Center(
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 32.0 : 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.store,
                  size: isLargeScreen ? 80 : 60,
                  color: Colors.grey,
                ),
                SizedBox(height: isLargeScreen ? 24 : 16),
                Text(
                  'Marketplace',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 32 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 16 : 12),
                Text(
                  'Coming Soon!',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 18 : 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 24 : 16),
                if (isLargeScreen)
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Get Notified'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;

        return Center(
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 32.0 : 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud,
                  size: isLargeScreen ? 80 : 60,
                  color: Colors.blue,
                ),
                SizedBox(height: isLargeScreen ? 24 : 16),
                Text(
                  'Weather Forecast',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 32 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 16 : 12),
                Text(
                  'Coming Soon!',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 18 : 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCropTrackerContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;

        return Center(
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 32.0 : 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.agriculture,
                  size: isLargeScreen ? 80 : 60,
                  color: Colors.green,
                ),
                SizedBox(height: isLargeScreen ? 24 : 16),
                Text(
                  'Crop Tracker',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 32 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 16 : 12),
                Text(
                  'Coming Soon!',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 18 : 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommunityContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;

        return Center(
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 32.0 : 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people,
                  size: isLargeScreen ? 80 : 60,
                  color: Colors.purple,
                ),
                SizedBox(height: isLargeScreen ? 24 : 16),
                Text(
                  'Community',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 32 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 16 : 12),
                Text(
                  'Coming Soon!',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 18 : 16,
                    color: Colors.grey,
                  ),
                ),
                if (isLargeScreen)
                  SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Join Community'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}