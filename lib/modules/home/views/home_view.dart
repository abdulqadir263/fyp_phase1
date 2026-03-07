import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/home_controller.dart';
import '../../../app/widgets/custom_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/role_guard.dart';

// Home screen ka UI
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App Bar
      appBar: AppBar(
        title: Text('app_name'.tr),
        centerTitle: true,
        actions: [
          // Notification bell icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Get.snackbar('info'.tr, 'notifications_coming_soon'.tr),
                tooltip: 'notifications'.tr,
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              ),
            ],
          ),
          // Language toggle button
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: controller.toggleLanguage,
            tooltip: 'change_language'.tr,
          ),
        ],
      ),

      // Side Drawer
      drawer: _buildDrawer(context),

      // Body — role-aware tab content
      body: Obx(() {
        final tabs = controller.bottomNavTabs;
        final idx = controller.currentIndex.value.clamp(0, tabs.length - 1);
        return IndexedStack(
          index: idx,
          children: tabs.map((tab) => _contentForTab(tab, context)).toList(),
        );
      }),

      // Floating Action Button for quick access
      floatingActionButton: _buildFloatingActionButton(),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Floating Action Button for quick access
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => controller.navigateToFeature('chatbot'),
      backgroundColor: AppConstants.primaryGreen,
      child: const Icon(Icons.chat, color: Colors.white),
      tooltip: 'agri_chatbot'.tr,
    );
  }

  // Profile placeholder widget
  Widget _buildProfilePlaceholder(bool isGuest) {
    return Icon(
      isGuest ? Icons.person_outline : Icons.person,
      size: 40,
      color: Colors.grey[600],
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
            final userName = controller.user.value?.name ?? 'guest_user'.tr;
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
                child: profileImageUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: profileImageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildProfilePlaceholder(isGuest),
                          errorWidget: (context, url, error) => _buildProfilePlaceholder(isGuest),
                        ),
                      )
                    : _buildProfilePlaceholder(isGuest),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryGreen,
                    AppConstants.darkGreen,
                  ],
                ),
              ),
            );
          }),

          // Drawer items
          ListTile(
            leading: const Icon(Icons.home),
            title: Text('home'.tr),
            onTap: () {
              Get.back(); // Drawer close karo
              controller.changePage(0); // Home tab select karo
            },
          ),

          // Profile tile with guest handling
          Obx(() => ListTile(
            leading: const Icon(Icons.person),
            title:
            Text(controller.isGuestUser ? 'create_account'.tr : 'profile'.tr),
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
            title: Text('settings'.tr),
            onTap: () {
              Get.back(); // Drawer close karo
              controller.goToSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text('about'.tr),
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
              controller.isGuestUser ? 'login_signup'.tr : 'logout'.tr,
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

  // Bottom Navigation Bar — dynamic per role
  Widget _buildBottomNavigationBar() {
    return Obx(() {
      final tabs = controller.bottomNavTabs;
      final idx = controller.currentIndex.value.clamp(0, tabs.length - 1);
      return BottomNavigationBar(
        currentIndex: idx,
        onTap: controller.changePage,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(Get.context!).primaryColor,
        unselectedItemColor: Colors.grey,
        items: tabs.map((tab) => _navItemForTab(tab)).toList(),
      );
    });
  }

  /// Map tab identifier → BottomNavigationBarItem (localized)
  BottomNavigationBarItem _navItemForTab(String tab) {
    switch (tab) {
      case 'home':
        return BottomNavigationBarItem(
            icon: const Icon(Icons.home), label: 'home'.tr);
      case 'marketplace':
        return BottomNavigationBarItem(
            icon: const Icon(Icons.store), label: 'marketplace'.tr);
      case 'weather':
        return BottomNavigationBarItem(
            icon: const Icon(Icons.cloud), label: 'weather_forecast'.tr);
      case 'crop_tracker':
        return BottomNavigationBarItem(
            icon: const Icon(Icons.agriculture), label: 'crop_tracker'.tr);
      case 'community':
        return BottomNavigationBarItem(
            icon: const Icon(Icons.people), label: 'community'.tr);
      case 'appointments':
        return BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today), label: 'appointments'.tr);
      default:
        return const BottomNavigationBarItem(
            icon: Icon(Icons.circle), label: '');
    }
  }

  /// Map tab identifier → content widget
  Widget _contentForTab(String tab, BuildContext context) {
    switch (tab) {
      case 'home':
        return _buildHomeContent(context);
      case 'marketplace':
        return _buildMarketplaceContent();
      case 'weather':
        return _buildWeatherContent();
      case 'crop_tracker':
        return _buildCropTrackerContent();
      case 'community':
        return _buildCommunityContent();
      case 'appointments':
        return _buildAppointmentsContent();
      default:
        return _buildHomeContent(context);
    }
  }

  /// Placeholder content for Appointments tab (experts)
  Widget _buildAppointmentsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;
        return Center(
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 32.0 : 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today,
                    size: isLargeScreen ? 80 : 60, color: Colors.blue),
                SizedBox(height: isLargeScreen ? 24 : 16),
                Text('appointments'.tr,
                    style: TextStyle(
                        fontSize: isLargeScreen ? 32 : 24,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: isLargeScreen ? 16 : 12),
                Text(
                  'coming_soon'.tr,
                  style: TextStyle(
                        fontSize: isLargeScreen ? 18 : 16,
                        color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Home tab content
  Widget _buildHomeContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;

        return RefreshIndicator(
          onRefresh: () async {
            await controller.refreshUserData();
          },
          color: AppConstants.primaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Message
                  Obx(() => Text(
                    controller.welcomeMessage,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )),

                  const SizedBox(height: 16),

                  // Weather Widget Card
                  _buildWeatherWidget(isLargeScreen),

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
                                  'browsing_as_guest'.tr,
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
                                  'profile_incomplete'.tr,
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontSize: isLargeScreen ? 16 : 14,
                                  ),
                                ),
                              ),
                              if (isLargeScreen) ...[
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => controller.goToProfile(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade800,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('complete_now'.tr),
                                ),
                              ] else ...[
                                TextButton(
                                  onPressed: () => controller.goToProfile(),
                                  child: Text(
                            'complete_now'.tr,
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

                // Quick Actions Section
                _buildSectionTitle('quick_actions'.tr, context),
                const SizedBox(height: 12),

                Text(
                  'what_to_do_today'.tr,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isLargeScreen ? 18 : 16,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 32 : 24),

                // Feature Cards Grid
                _buildResponsiveFeatureGrid(context),

                const SizedBox(height: 24),

                // Farmer Tips Carousel
                _buildFarmerTipsCarousel(isLargeScreen),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  // Weather Widget Card
  Widget _buildWeatherWidget(bool isLargeScreen) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isLargeScreen ? 20 : 16),
      padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.navigateToFeature('weather'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.wb_sunny,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Weather',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'tap_detailed_forecast'.tr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Section Title
  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  // Farmer Tips Carousel
  Widget _buildFarmerTipsCarousel(bool isLargeScreen) {
    final tips = [
      {'icon': Icons.water_drop, 'tip': 'tip_water', 'color': Colors.blue},
      {'icon': Icons.bug_report, 'tip': 'tip_pest', 'color': Colors.red},
      {'icon': Icons.eco, 'tip': 'tip_organic', 'color': Colors.green},
      {'icon': Icons.cloud, 'tip': 'tip_weather', 'color': Colors.orange},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('farming_tips'.tr, Get.context!),
        const SizedBox(height: 12),
        SizedBox(
          height: isLargeScreen ? 120 : 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Container(
                width: isLargeScreen ? 280 : 220,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (tip['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (tip['color'] as Color).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tip['icon'] as IconData,
                      color: tip['color'] as Color,
                      size: isLargeScreen ? 32 : 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (tip['tip'] as String).tr,
                        style: TextStyle(
                          fontSize: isLargeScreen ? 14 : 12,
                          color: Colors.grey[800],
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Responsive Grid build karna
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
          children: _buildRoleAwareFeatureCards(),
        );
      },
    );
  }

  /// Build feature cards based on RoleGuard.allowedFeatures
  List<Widget> _buildRoleAwareFeatureCards() {
    final allowed = RoleGuard.allowedFeatures;
    final cards = <Widget>[];

    // Map feature identifiers to card configs (localized)
    final allCards = {
      'appointments': {
        'title': 'book_appointment',
        'icon': Icons.calendar_today,
        'color': Colors.blue,
        'feature': 'appointments',
      },
      'marketplace': {
        'title': 'marketplace',
        'icon': Icons.shopping_cart,
        'color': Colors.green,
        'feature': 'marketplace',
      },
      'weather': {
        'title': 'weather_advice',
        'icon': Icons.cloud,
        'color': Colors.orange,
        'feature': 'weather',
      },
      'crop_tracker': {
        'title': 'crop_tracker',
        'icon': Icons.agriculture,
        'color': Colors.brown,
        'feature': 'crop_tracker',
      },
      'community': {
        'title': 'community',
        'icon': Icons.people,
        'color': Colors.purple,
        'feature': 'community',
      },
      'chatbot': {
        'title': 'agri_chatbot',
        'icon': Icons.chat,
        'color': Colors.teal,
        'feature': 'chatbot',
      },
      'crop_recommendation': {
        'title': 'crop_recommendation',
        'icon': Icons.eco,
        'color': Colors.lightGreen,
        'feature': 'crop_recommendation',
      },
    };

    for (final id in allowed) {
      final cfg = allCards[id];
      if (cfg != null) {
        cards.add(_buildFeatureCard(
          title: (cfg['title'] as String).tr,
          icon: cfg['icon'] as IconData,
          color: cfg['color'] as Color,
          onTap: () => controller.navigateToFeature(cfg['feature'] as String),
        ));
      }
    }

    // Always add upcoming features for farmers
    if (RoleGuard.currentUserType == 'farmer') {
      cards.add(_buildFeatureCard(
        title: 'disease_detection'.tr,
        icon: Icons.bug_report,
        color: Colors.red,
        onTap: () => controller.navigateToFeature('disease_detection'),
      ));
    }

    return cards;
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
                  'marketplace'.tr,
                  style: TextStyle(
                    fontSize: isLargeScreen ? 32 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 16 : 12),
                Text(
                  'coming_soon'.tr,
                  style: TextStyle(
                    fontSize: isLargeScreen ? 18 : 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 24 : 16),
                if (isLargeScreen)
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('get_notified'.tr),
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
                  'weather_forecast'.tr,
                  style: TextStyle(
                    fontSize: isLargeScreen ? 32 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 16 : 12),
                Text(
                  'coming_soon'.tr,
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
                  'crop_tracker'.tr,
                  style: TextStyle(
                    fontSize: isLargeScreen ? 32 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 16 : 12),
                Text(
                  'coming_soon'.tr,
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
                  'community'.tr,
                  style: TextStyle(
                    fontSize: isLargeScreen ? 32 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 16 : 12),
                Text(
                  'coming_soon'.tr,
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
                  child: Text('join_community'.tr),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}