import 'package:get/get.dart';
import '../controllers/marketplace_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/seller_controller.dart';
import '../controllers/order_controller.dart';
import '../services/marketplace_service.dart';

/// Binding for the Marketplace module
class MarketplaceBinding extends Bindings {
  @override
  void dependencies() {
    // Service — registered as permanent in main.dart, but guard here too
    if (!Get.isRegistered<MarketplaceService>()) {
      Get.lazyPut<MarketplaceService>(() => MarketplaceService(), fenix: true);
    }

    if (!Get.isRegistered<MarketplaceController>()) {
      Get.lazyPut<MarketplaceController>(
        () => MarketplaceController(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CartController>()) {
      Get.lazyPut<CartController>(() => CartController(), fenix: true);
    }

    if (!Get.isRegistered<SellerController>()) {
      Get.lazyPut<SellerController>(() => SellerController(), fenix: true);
    }

    if (!Get.isRegistered<OrderController>()) {
      Get.lazyPut<OrderController>(() => OrderController(), fenix: true);
    }
  }
}
