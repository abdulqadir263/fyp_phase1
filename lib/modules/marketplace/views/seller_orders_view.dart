import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../controllers/seller_controller.dart';
import '../models/order_model.dart';

/// SellerOrdersView — Seller views and updates status of incoming orders
class SellerOrdersView extends GetView<SellerController> {
  const SellerOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadSellerOrders();

    return Scaffold(
      appBar: AppBar(title: Text('customer_orders'.tr), centerTitle: true),
      body: SafeArea(
        top: false,
        child: ResponsiveHelper.tabletCenter(
          child: Obx(() {
            if (controller.isLoadingOrders.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              );
            }

            if (controller.sellerOrders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No orders yet.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.loadSellerOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.sellerOrders.length,
                itemBuilder: (_, i) =>
                    _OrderCard(order: controller.sellerOrders[i]),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SellerController>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Buyer: ${order.buyerName}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),

            // Items
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• ${item['name']} × ${item['quantity']}  —  Rs. ${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),

            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'total'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '📍 ${order.deliveryAddress}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              '📞 ${order.phone}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),

            // Status update buttons
            if (order.status != 'delivered' && order.status != 'cancelled') ...[
              const SizedBox(height: 10),
              _buildStatusActions(ctrl, order),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActions(SellerController ctrl, OrderModel order) {
    switch (order.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => ctrl.updateOrderStatus(order, 'confirmed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                child: Text(
                  'confirm'.tr,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => ctrl.updateOrderStatus(order, 'cancelled'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
                child: Text('cancel'.tr, style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        );
      case 'confirmed':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => ctrl.updateOrderStatus(order, 'shipped'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: Text(
              'mark_shipped'.tr,
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      case 'shipped':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => ctrl.updateOrderStatus(order, 'delivered'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: Text(
              'mark_delivered'.tr,
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'pending':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;
      case 'confirmed':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        break;
      case 'shipped':
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade800;
        break;
      case 'delivered':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case 'cancelled':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${status[0].toUpperCase()}${status.substring(1)}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
