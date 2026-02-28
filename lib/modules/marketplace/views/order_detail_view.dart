import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/themes/app_colors.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';

/// OrderDetailView — Full order details with live status step indicator
class OrderDetailView extends GetView<OrderController> {
  const OrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details'), centerTitle: true),
      body: StreamBuilder<OrderModel?>(
        stream: controller.orderStream,
        initialData: controller.selectedOrder.value,
        builder: (context, snapshot) {
          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Order ID + Date ──
                Text(
                  'Order #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 24),

                // ── Status Tracker (live) ──
                const Text('Order Status',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _StatusTracker(currentStatus: order.status),

                const SizedBox(height: 24),

                // ── Items ──
                const Text('Items',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    'Qty: ${item['quantity']}  ×  Rs. ${(item['price'] as num).toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Text(
                            'Rs. ${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    )),

                const Divider(height: 20),

                // ── Price breakdown ──
                _priceRow('Subtotal',
                    'Rs. ${order.subtotal.toStringAsFixed(0)}'),
                _priceRow('Delivery Fee',
                    'Rs. ${order.deliveryFee.toStringAsFixed(0)}'),
                const Divider(height: 16),
                _priceRow('Total',
                    'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                    bold: true),

                const SizedBox(height: 20),

                // ── Delivery info ──
                const Text('Delivery Details',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _infoTile(Icons.location_on_outlined, order.deliveryAddress),
                const SizedBox(height: 4),
                _infoTile(Icons.phone_outlined, order.phone),
                const SizedBox(height: 10),

                // ── Payment method ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.payments_outlined,
                          color: Colors.orange, size: 22),
                      SizedBox(width: 10),
                      Text('Cash on Delivery',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: bold ? AppColors.primaryGreen : null)),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
//  VISUAL STATUS STEP TRACKER
// ═══════════════════════════════════════════

class _StatusTracker extends StatelessWidget {
  final String currentStatus;
  const _StatusTracker({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    // Cancelled is shown as a special state
    if (currentStatus == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            Text('Order Cancelled',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700)),
          ],
        ),
      );
    }

    final steps = ['pending', 'confirmed', 'shipped', 'delivered'];
    final currentIdx = steps.indexOf(currentStatus);

    return Column(
      children: List.generate(steps.length, (i) {
        final isCompleted = i <= currentIdx;
        final isCurrent = i == currentIdx;
        final isLast = i == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle + line
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isCompleted ? AppColors.primaryGreen : Colors.grey.shade300,
                    border: isCurrent
                        ? Border.all(color: AppColors.primaryGreen, width: 3)
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 3,
                    height: 36,
                    color: i < currentIdx
                        ? AppColors.primaryGreen
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Label
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stepLabel(steps[i]),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                  if (isCurrent)
                    Text(
                      _stepHint(steps[i]),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  SizedBox(height: isLast ? 0 : 18),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  String _stepLabel(String step) {
    switch (step) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed by Seller';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      default:
        return step;
    }
  }

  String _stepHint(String step) {
    switch (step) {
      case 'pending':
        return 'Waiting for seller confirmation';
      case 'confirmed':
        return 'Seller confirmed your order';
      case 'shipped':
        return 'Your order is on the way';
      case 'delivered':
        return 'Order delivered successfully!';
      default:
        return '';
    }
  }
}

