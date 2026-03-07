import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/role_guard.dart';
import '../../../core/utils/responsive_helper.dart';
import '../controllers/marketplace_controller.dart';
import '../controllers/cart_controller.dart';
import '../models/product_model.dart';

/// MarketplaceHomeView — Role-aware entry point
/// Company → redirected to seller dashboard (handled by middleware + fallback)
/// Farmer  → buyer UI with search, categories, cart, order history
class MarketplaceHomeView extends GetView<MarketplaceController> {
  const MarketplaceHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Defensive fallback: redirect company to seller dashboard ──
    // Primary guard is RoleMiddleware, but this catches edge cases
    if (RoleGuard.currentUserType == 'company') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed(AppRoutes.SELLER_DASHBOARD);
      });
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('marketplace'.tr),
        centerTitle: true,
        actions: [
          // Order history
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'My Orders',
            onPressed: () => Get.toNamed(AppRoutes.ORDER_HISTORY),
          ),
          // Cart icon with badge (farmer only)
          Obx(() {
            final count = Get.find<CartController>().itemCount;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => Get.toNamed(AppRoutes.MARKETPLACE_CART),
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text('$count',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'search_products'.tr,
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.primaryGreen),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ── Category chips (Wrap prevents overflow on small screens) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('All', controller.selectedCategory.value.isEmpty,
                        () => controller.setCategory('')),
                    ...ProductModel.categories.map((cat) => _chip(
                          '${cat[0].toUpperCase()}${cat.substring(1)}',
                          controller.selectedCategory.value == cat,
                          () => controller.setCategory(cat),
                        )),
                  ],
                )),
          ),

          // ── Products grid (responsive columns) ──
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGreen),
                );
              }

              if (controller.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No products found.',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadProducts,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final r = ResponsiveHelper.of(context);
                    return GridView.builder(
                      padding: EdgeInsets.all(r.padding),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: r.gridCrossAxisCount(minItemWidth: 160),
                        childAspectRatio: r.productGridAspectRatio,
                        crossAxisSpacing: r.scale(12),
                        mainAxisSpacing: r.scale(12),
                      ),
                      itemCount: controller.products.length,
                      itemBuilder: (_, i) => _ProductCard(
                        product: controller.products[i],
                        onTap: () =>
                            controller.openProductDetail(controller.products[i]),
                        onAddToCart: () => Get.find<CartController>()
                            .addToCart(controller.products[i]),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppColors.primaryGreen,
                fontWeight: FontWeight.w600)),
        backgroundColor:
            selected ? AppColors.primaryGreen : AppColors.lightGreen.withValues(alpha: 0.3),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

/// Product grid card
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1.2,
              child: product.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: Icon(Icons.image, color: Colors.grey))),
                      errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image)),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                          child: Icon(Icons.inventory, size: 40))),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Rs. ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen)),
                    Text(product.sellerName,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: product.stock > 0 ? onAddToCart : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
