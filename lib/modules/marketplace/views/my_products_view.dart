import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../controllers/seller_controller.dart';
import '../models/product_model.dart';

/// SellerProductsView — Company user manages their products (CRUD + toggle)
class SellerProductsView extends GetView<SellerController> {
  const SellerProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadMyProducts();

    return Scaffold(
      appBar: AppBar(title: Text('my_products'.tr), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_product_fab',
        onPressed: () {
          controller.prepareNewProduct();
          Get.toNamed('/marketplace/seller/add-product');
        },
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('add_to_cart'.tr, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveHelper.tabletCenter(
          child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }

        if (controller.myProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No products yet. Add your first!',
                    style:
                        TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadMyProducts,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: controller.myProducts.length,
            itemBuilder: (_, i) =>
                _SellerProductCard(product: controller.myProducts[i]),
          ),
        );
      }),
        ),
      ),
    );
  }
}

class _SellerProductCard extends StatelessWidget {
  final ProductModel product;
  const _SellerProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SellerController>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: product.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover)
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.inventory, size: 32)),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Rs. ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 17,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Stock: ${product.stock}',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(width: 10),
                          Text('• ${product.categoryLabel}',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Active / Inactive badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: product.isActive
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: product.isActive
                                ? Colors.green.shade800
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 18),

            // ── Action buttons row ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ctrl.prepareEditProduct(product);
                      Get.toNamed('/marketplace/seller/add-product');
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text('edit'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ctrl.toggleActive(product),
                    icon: Icon(
                        product.isActive
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 18),
                    label: Text(product.isActive ? 'Hide' : 'Show'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade400),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    Get.dialog(AlertDialog(
                      title: Text('delete_product'.tr),
                      content: Text('cannot_be_undone'.tr),
                      actions: [
                        TextButton(
                            onPressed: () => Get.back(),
                            child: Text('cancel'.tr)),
                        TextButton(
                          onPressed: () {
                            Get.back();
                            ctrl.deleteProduct(product);
                          },
                          child: Text('delete'.tr,
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
