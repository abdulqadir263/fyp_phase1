import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/utils/role_guard.dart';
import '../../../core/utils/responsive_helper.dart';
import '../view_model/marketplace_controller.dart';
import '../view_model/cart_controller.dart';

/// ProductDetailView — Full product info with quantity selector & add to cart
/// Cart actions hidden for roles without cart access
class ProductDetailView extends GetView<MarketplaceController> {
  const ProductDetailView({super.key});

  /// Whether current user can buy (has cart permission)
  bool get _isBuyer => RoleGuard.currentUserCanAccess(RoleGuard.cart);

  @override
  Widget build(BuildContext context) {
    final quantity = 1.obs;

    return Scaffold(
      appBar: AppBar(title: Text('product_details'.tr), centerTitle: true),
      body: SafeArea(
        top: false, // AppBar already handles top
        child: ResponsiveHelper.tabletCenter(
          child: Obx(() {
            final product = controller.selectedProduct.value;
            if (product == null) {
              return const Center(child: Text('Product not found.'));
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image ──
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.inventory, size: 64),
                            ),
                          ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.categoryLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Name
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Price
                        Text(
                          'Rs. ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Stock
                        Row(
                          children: [
                            Icon(
                              product.stock > 0
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 18,
                              color: product.stock > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              product.stock > 0
                                  ? '${product.stock} in stock'
                                  : 'Out of stock',
                              style: TextStyle(
                                fontSize: 14,
                                color: product.stock > 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Seller
                        Text(
                          'Sold by: ${product.sellerName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          'description'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.description,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                        const SizedBox(height: 24),

                        // ── Quantity selector (buyer only) ──
                        if (product.stock > 0 && _isBuyer) ...[
                          Text(
                            'quantity'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Obx(
                            () => Row(
                              children: [
                                _qtyButton(Icons.remove, () {
                                  if (quantity.value > 1) quantity.value--;
                                }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    '${quantity.value}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _qtyButton(Icons.add, () {
                                  if (quantity.value < product.stock) {
                                    quantity.value++;
                                  }
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Add to Cart
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Get.find<CartController>().addToCart(
                                  product,
                                  quantity: quantity.value,
                                );
                              },
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                color: Colors.white,
                              ),
                              label: Text(
                                'add_to_cart'.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryGreen),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryGreen),
      ),
    );
  }
}
