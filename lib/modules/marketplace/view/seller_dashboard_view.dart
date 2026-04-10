import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/responsive_helper.dart';
import '../view_model/seller_controller.dart';

/// SellerDashboardView — Company landing page with summary cards + navigation
class SellerDashboardView extends GetView<SellerController> {
  const SellerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure data is loaded
    controller.loadMyProducts();
    controller.loadSellerOrders();

    return Scaffold(
      appBar: AppBar(title: Text('seller_dashboard'.tr), centerTitle: true),
      body: Obx(() {
        final totalProducts = controller.myProducts.length;
        final activeProducts = controller.myProducts
            .where((p) => p.isActive)
            .length;
        final pendingOrders = controller.sellerOrders
            .where((o) => o.status == 'pending')
            .length;
        final completedOrders = controller.sellerOrders
            .where((o) => o.status == 'delivered')
            .length;

        return SafeArea(
          child: ResponsiveHelper.tabletCenter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'overview'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Summary cards grid (responsive) ──
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final r = ResponsiveHelper.of(context);
                      // Adjust aspect ratio based on available width
                      final aspectRatio = r.isSmallPhone ? 1.3 : 1.5;
                      final crossAxisCount = r.isTablet ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: r.scale(12),
                        mainAxisSpacing: r.scale(12),
                        childAspectRatio: aspectRatio,
                        children: [
                          _SummaryCard(
                            icon: Icons.inventory_2,
                            label: 'total_products'.tr,
                            value: '$totalProducts',
                            color: Colors.blue,
                          ),
                          _SummaryCard(
                            icon: Icons.check_circle,
                            label: 'active_products'.tr,
                            value: '$activeProducts',
                            color: AppColors.primaryGreen,
                          ),
                          _SummaryCard(
                            icon: Icons.pending_actions,
                            label: 'pending_orders'.tr,
                            value: '$pendingOrders',
                            color: Colors.orange,
                          ),
                          _SummaryCard(
                            icon: Icons.done_all,
                            label: 'completed'.tr,
                            value: '$completedOrders',
                            color: Colors.teal,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── Quick actions ──
                  Text(
                    'quick_actions'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Manage Products
                  _ActionCard(
                    icon: Icons.storefront,
                    title: 'my_products'.tr,
                    subtitle: 'manage_products'.tr,
                    onTap: () => Get.toNamed(AppRoutes.SELLER_PRODUCTS),
                  ),
                  const SizedBox(height: 10),

                  // View Orders
                  _ActionCard(
                    icon: Icons.receipt_long,
                    title: 'Customer Orders',
                    subtitle: 'View and update order statuses',
                    trailing: pendingOrders > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$pendingOrders new',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => Get.toNamed(AppRoutes.SELLER_ORDERS),
                  ),
                  const SizedBox(height: 10),

                  // Add new product shortcut
                  _ActionCard(
                    icon: Icons.add_box,
                    title: 'Add New Product',
                    subtitle: 'List a new product for sale',
                    onTap: () {
                      controller.prepareNewProduct();
                      Get.toNamed(AppRoutes.SELLER_ADD_PRODUCT);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Summary card showing a number + label
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation action card
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
          radius: 24,
          child: Icon(icon, color: AppColors.primaryGreen, size: 26),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primaryGreen,
            ),
        onTap: onTap,
      ),
    );
  }
}
