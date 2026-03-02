import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/utils/role_guard.dart';
import '../controllers/cart_controller.dart';

/// CheckoutView — Delivery address & phone, then place COD order
/// Non-authorized roles are redirected by middleware + defensive fallback
class CheckoutView extends GetView<CartController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Defensive fallback: only cart-authorized roles ──
    if (!RoleGuard.currentUserCanAccess(RoleGuard.cart)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed(RoleGuard.currentDefaultRoute);
      });
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
      body: Obx(() {
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary
                  const Text('Order Summary',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...controller.cartItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(
                                    '${item.productName} x ${item.quantity}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            Text(
                                'Rs. ${item.totalPrice.toStringAsFixed(0)}'),
                          ],
                        ),
                      )),
                  const Divider(height: 16),
                  _row('Subtotal',
                      'Rs. ${controller.subtotal.toStringAsFixed(0)}'),
                  _row('Delivery Fee',
                      'Rs. ${controller.deliveryFee.toStringAsFixed(0)}'),
                  const Divider(height: 16),
                  _row('Total',
                      'Rs. ${controller.totalAmount.toStringAsFixed(0)}',
                      bold: true),

                  const SizedBox(height: 24),

                  // Delivery address
                  const Text('Delivery Address',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.addressController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Village, Street, City, District',
                      prefixIcon: const Icon(Icons.location_on_outlined,
                          color: AppColors.primaryGreen),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Phone
                  const Text('Phone Number',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '03xx-xxxxxxx',
                      prefixIcon: const Icon(Icons.phone_outlined,
                          color: AppColors.primaryGreen),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // COD notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.payments_outlined,
                            color: Colors.orange, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cash on Delivery\nPay when product is delivered.',
                            style: TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Place Order button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.isPlacingOrder.value
                          ? null
                          : controller.placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Place Order (Cash on Delivery)',
                          style: TextStyle(fontSize: 17, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Loading overlay
            if (controller.isPlacingOrder.value)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: AppColors.primaryGreen),
                          SizedBox(height: 16),
                          Text('Placing your order...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
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
}

