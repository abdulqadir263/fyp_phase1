import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/routes/app_routes.dart';
import '../view_model/home_controller.dart';
import '../../../app/widgets/custom_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/role_guard.dart';
import '../../marketplace/view/marketplace_view.dart';
import '../../marketplace/view/seller_dashboard_view.dart';
import '../../community/view/community_view.dart';
import '../../appointments/view/farmer_appointments_view.dart';
import '../../appointments/view/expert_appointments_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomeController>();
  }

  void _closeDrawer() => _scaffoldKey.currentState?.closeDrawer();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tabs = controller.bottomNavTabs;
      final idx = controller.currentIndex.value.clamp(0, tabs.length - 1);
      final isHome = tabs[idx] == 'home';

      return Scaffold(
        key: _scaffoldKey,
        appBar: isHome
            ? AppBar(
                title: Text('app_name'.tr),
                centerTitle: true,
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () => Get.snackbar(
                            'info'.tr, 'notifications_coming_soon'.tr),
                        tooltip: 'notifications'.tr,
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          constraints:
                              const BoxConstraints(minWidth: 8, minHeight: 8),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.language),
                    onPressed: controller.toggleLanguage,
                    tooltip: 'change_language'.tr,
                  ),
                ],
              )
            : null,
        drawer: isHome ? _buildDrawer(context) : null,
        body: _contentForTab(tabs[idx], context),
        floatingActionButton: isHome && RoleGuard.currentUserType != 'expert'
            ? FloatingActionButton(
                onPressed: () => controller.navigateToFeature('chatbot'),
                backgroundColor: AppConstants.primaryGreen,
                tooltip: 'agri_chatbot'.tr,
                child: const Icon(Icons.chat, color: Colors.white),
              )
            : null,
        bottomNavigationBar: _buildBottomNavigationBar(context),
      );
    });
  }

  Widget _buildProfilePlaceholder(bool isGuest) {
    return Icon(isGuest ? Icons.person_outline : Icons.person,
        size: 40, color: Colors.grey[600]);
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(() {
            final userName = controller.user.value?.name ?? 'guest_user'.tr;
            final userEmail =
                controller.user.value?.email ?? 'guest@example.com';
            final isGuest = controller.isGuestUser;
            final profileImageUrl = controller.profileImageUrl;
            return UserAccountsDrawerHeader(
              accountName: Text(userName,
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              accountEmail: Text(userEmail,
                  style: const TextStyle(color: Colors.white70)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: profileImageUrl.isNotEmpty
                    ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: profileImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        _buildProfilePlaceholder(isGuest),
                    errorWidget: (context, url, error) =>
                        _buildProfilePlaceholder(isGuest),
                  ),
                )
                    : _buildProfilePlaceholder(isGuest),
              ),
              decoration:
              const BoxDecoration(color: AppConstants.primaryGreen),
            );
          }),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text('home'.tr),
            onTap: () {
              _closeDrawer();
              controller.changePage(0);
            },
          ),
          Obx(() => ListTile(
            leading: const Icon(Icons.person),
            title: Text(controller.isGuestUser
                ? 'create_account'.tr
                : 'profile'.tr),
            onTap: () {
              _closeDrawer();
              if (controller.isGuestUser) {
                Get.offAllNamed(AppRoutes.WELCOME);
              } else {
                controller.goToProfile();
              }
            },
          )),

          // ── My Appointments drawer entry (farmer + expert only) ───────────
          Obx(() {
            final role = controller.user.value?.userType;
            if (role != 'farmer' && role != 'expert') {
              return const SizedBox.shrink();
            }
            return ListTile(
              leading: Icon(
                Icons.calendar_month,
                color: role == 'expert'
                    ? const Color(0xFF1565C0)
                    : AppConstants.primaryGreen,
              ),
              title: Text('My Appointments'.tr),
              onTap: () {
                _closeDrawer();
                controller.navigateToFeature('My Appointments');
              },
            );
          }),
          // ─────────────────────────────────────────────────────────────────

          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text('settings'.tr),
            onTap: () {
              _closeDrawer();
              controller.goToSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text('about'.tr),
            onTap: () {
              _closeDrawer();
              controller.goToAbout();
            },
          ),
          const Divider(),
          Obx(() => ListTile(
            leading: Icon(
              controller.isGuestUser ? Icons.login : Icons.logout,
              color:
              controller.isGuestUser ? Colors.green : Colors.red,
            ),
            title: Text(
              controller.isGuestUser ? 'login_signup'.tr : 'logout'.tr,
              style: TextStyle(
                  color: controller.isGuestUser
                      ? Colors.green
                      : Colors.red),
            ),
            onTap: () {
              _closeDrawer();
              if (controller.isGuestUser) {
                Get.offAllNamed(AppRoutes.WELCOME);
              } else {
                controller.logout();
              }
            },
          )),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Obx(() {
      final tabs = controller.bottomNavTabs;
      final idx = controller.currentIndex.value.clamp(0, tabs.length - 1);
      return BottomNavigationBar(
        currentIndex: idx,
        onTap: controller.changePage,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: tabs.map((tab) => _navItemForTab(tab)).toList(),
      );
    });
  }

  BottomNavigationBarItem _navItemForTab(String tab) {
    switch (tab) {
      case 'home':
        return BottomNavigationBarItem(
            icon: const Icon(Icons.home), label: 'home'.tr);
      case 'marketplace':
        return BottomNavigationBarItem(
            icon: const Icon(Icons.store), label: 'marketplace'.tr);
      case 'community':
        return BottomNavigationBarItem(
            icon: const Icon(Icons.people), label: 'community'.tr);
      case 'appointments':
        return BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_outlined),
            activeIcon: const Icon(Icons.calendar_month),
            label: 'My Appointments'.tr);
      default:
        return const BottomNavigationBarItem(
            icon: Icon(Icons.circle), label: '');
    }
  }

  Widget _contentForTab(String tab, BuildContext context) {
    switch (tab) {
      case 'home':
        return _buildHomeContent(context);
      case 'marketplace':
        return controller.user.value?.userType == 'company'
            ? const SellerDashboardView()
            : const MarketplaceHomeView();
      case 'community':
        return const CommunityView();
      case 'appointments':
        return controller.user.value?.userType == 'expert'
            ? const ExpertAppointmentsView()
            : const FarmerAppointmentsView();
      default:
        return _buildHomeContent(context);
    }
  }

  Widget _buildHomeContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;
        return RefreshIndicator(
          onRefresh: () async => await controller.refreshUserData(),
          color: AppConstants.primaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
            child: ConstrainedBox(
              constraints:
              BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Text(
                    controller.welcomeMessage,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  )),
                  const SizedBox(height: 16),
                  if (RoleGuard.currentUserType != 'expert')
                    _buildWeatherWidget(isLargeScreen),
                  Obx(() => controller.isGuestUser
                      ? _buildBanner(
                      isLargeScreen: isLargeScreen,
                      color: Colors.orange.shade800,
                      text: 'browsing_as_guest'.tr)
                      : const SizedBox.shrink()),
                  Obx(() => controller.isProfileIncomplete &&
                      !controller.isGuestUser
                      ? _buildBanner(
                      isLargeScreen: isLargeScreen,
                      color: Colors.blue.shade800,
                      text: 'profile_incomplete'.tr,
                      onAction: controller.goToProfile,
                      actionLabel: 'complete_now'.tr)
                      : const SizedBox.shrink()),
                  SizedBox(height: isLargeScreen ? 8 : 4),
                  _buildSectionTitle('quick_actions'.tr, context),
                  const SizedBox(height: 12),
                  Text('what_to_do_today'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                          color: Colors.grey[600],
                          fontSize: isLargeScreen ? 18 : 16)),
                  SizedBox(height: isLargeScreen ? 32 : 24),
                  _buildResponsiveFeatureGrid(context),
                  if (RoleGuard.currentUserType != 'expert') ...[
                    const SizedBox(height: 24),
                    _buildFarmerTipsCarousel(isLargeScreen, context),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBanner({
    required bool isLargeScreen,
    required Color color,
    required String text,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final bgColor = color.withValues(alpha: 0.12);
    final borderColor = color.withValues(alpha: 0.4);
    final textColor = color;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: isLargeScreen ? 20 : 16),
      padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: textColor),
          SizedBox(width: isLargeScreen ? 12 : 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: textColor,
                    fontSize: isLargeScreen ? 16 : 14)),
          ),
          if (onAction != null && actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel,
                  style: TextStyle(
                      color: textColor, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget(bool isLargeScreen) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isLargeScreen ? 20 : 16),
      padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () => controller.navigateToFeature('weather'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wb_sunny,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Weather",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('tap_detailed_forecast'.tr,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold, color: Colors.grey[800]));
  }

  Widget _buildFarmerTipsCarousel(bool isLargeScreen, BuildContext context) {
    final tips = [
      {'icon': Icons.water_drop, 'tip': 'tip_water', 'color': Colors.blue},
      {'icon': Icons.bug_report, 'tip': 'tip_pest', 'color': Colors.red},
      {'icon': Icons.eco, 'tip': 'tip_organic', 'color': Colors.green},
      {'icon': Icons.cloud, 'tip': 'tip_weather', 'color': Colors.orange},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('farming_tips'.tr, context),
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
                  color:
                  (tip['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: (tip['color'] as Color)
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(tip['icon'] as IconData,
                        color: tip['color'] as Color,
                        size: isLargeScreen ? 32 : 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text((tip['tip'] as String).tr,
                          style: TextStyle(
                              fontSize: isLargeScreen ? 14 : 12,
                              color: Colors.grey[800],
                              height: 1.3),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
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

  Widget _buildResponsiveFeatureGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        int cols;
        double ratio, hSpacing, vSpacing;
        if (w > 1200) {
          cols = 4; ratio = 1.0; hSpacing = 24; vSpacing = 24;
        } else if (w > 800) {
          cols = 3; ratio = 1.0; hSpacing = 20; vSpacing = 20;
        } else if (w > 600) {
          cols = 3; ratio = 1.0; hSpacing = 16; vSpacing = 16;
        } else if (w > 400) {
          cols = 2; ratio = 1.1; hSpacing = 12; vSpacing = 12;
        } else {
          cols = 2; ratio = 0.9; hSpacing = 8; vSpacing = 8;
        }
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          crossAxisSpacing: hSpacing,
          mainAxisSpacing: vSpacing,
          childAspectRatio: ratio,
          padding: EdgeInsets.zero,
          children: _buildRoleAwareFeatureCards(),
        );
      },
    );
  }

  List<Widget> _buildRoleAwareFeatureCards() {
    final allowed = RoleGuard.allowedFeatures;
    final role = RoleGuard.currentUserType;

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

    final cards = <Widget>[];
    for (final id in allowed) {
      // Expert sees "View Appointments" instead of "Book Appointment"
      if (id == 'appointments' && role == 'expert') {
        cards.add(_buildFeatureCard(
          title: 'View Appointments',
          icon: Icons.calendar_month,
          color: const Color(0xFF1565C0),
          onTap: () => Get.toNamed(AppRoutes.EXPERT_APPOINTMENTS),
        ));
        continue;
      }
      final cfg = allCards[id];
      if (cfg != null) {
        cards.add(_buildFeatureCard(
          title: (cfg['title'] as String).tr,
          icon: cfg['icon'] as IconData,
          color: cfg['color'] as Color,
          onTap: () =>
              controller.navigateToFeature(cfg['feature'] as String),
        ));
      }
    }

    // Disease detection for farmers
    if (role == 'farmer') {
      cards.add(_buildFeatureCard(
        title: 'disease_detection'.tr,
        icon: Icons.bug_report,
        color: Colors.red,
        onTap: () => controller.navigateToFeature('disease_detection'),
      ));
    }

    // ── My Appointments card (farmer + expert) ────────────────────────────
    // if (role == 'farmer' || role == 'expert') {
    //   cards.add(_buildFeatureCard(
    //     title: 'My Appointments'.tr,
    //     icon: Icons.history,
    //     color: role == 'expert'
    //         ? const Color(0xFF1565C0)
    //         : AppConstants.primaryGreen,
    //     onTap: () => controller.navigateToFeature('My Appointments'),
    //   ));
    // }
    // ─────────────────────────────────────────────────────────────────────

    return cards;
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final iconSize = (w * 0.25).clamp(24.0, 40.0);
        final fontSize = (w * 0.09).clamp(12.0, 16.0);
        return CustomCard(
          onTap: onTap,
          padding: EdgeInsets.all(w * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.08),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconSize, color: color),
              ),
              SizedBox(height: h * 0.05),
              Flexible(
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      },
    );
  }
}