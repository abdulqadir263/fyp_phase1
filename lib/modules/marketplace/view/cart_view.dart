import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/utils/role_guard.dart';
import '../view_model/cart_controller.dart';
import '../models/cart_item_model.dart';

/// CartView — Shows cart items, quantities, totals, and checkout button
/// Non-authorized roles are redirected by middleware + defensive fallback
class CartView extends GetView<CartController> {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Defensive fallback: only cart-authorized roles ──
    if (!RoleGuard.currentUserCanAccess(RoleGuard.cart)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed(RoleGuard.currentDefaultRoute);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('my_cart'.tr), centerTitle: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (controller.cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'your_cart_empty'.tr,
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                  ),
                  child: Text(
                    'browse_products'.tr,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // ── Item list ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.cartItems.length,
                itemBuilder: (_, i) =>
                    _CartItemCard(item: controller.cartItems[i]),
              ),
            ),

            // ── Order summary & checkout button ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 2),
                ),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    'subtotal'.tr,
                    'Rs. ${controller.subtotal.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 4),
                  _summaryRow(
                    'delivery_fee'.tr,
                    'Rs. ${controller.deliveryFee.toStringAsFixed(0)}',
                  ),
                  const Divider(height: 16),
                  _summaryRow(
                    'total'.tr,
                    'Rs. ${controller.totalAmount.toStringAsFixed(0)}',
                    bold: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💵 ${'cod_message'.tr}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed('/marketplace/checkout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'proceed_to_checkout'.tr,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppColors.primaryGreen : null,
          ),
        ),
      ],
    );
  }
}

/// Single cart item card with quantity controls
class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CartController>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.inventory),
                    ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Quantity controls
                  Row(
                    children: [
                      _smallBtn(
                        Icons.remove,
                        () => ctrl.updateQuantity(
                          item.productId,
                          item.quantity - 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _smallBtn(
                        Icons.add,
                        () => ctrl.updateQuantity(
                          item.productId,
                          item.quantity + 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove & total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => ctrl.removeItem(item.productId),
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
