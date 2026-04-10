import 'package:get/get.dart';
import '../view_model/marketplace_controller.dart';
import '../view_model/cart_controller.dart';
import '../view_model/seller_controller.dart';
import '../view_model/order_controller.dart';
import '../repository/marketplace_repository.dart';

/// Binding for the Marketplace module
class MarketplaceBinding extends Bindings {
  @override
  void dependencies() {
    // Service — registered as permanent in main.dart, but guard here too
    if (!Get.isRegistered<MarketplaceRepository>()) {
      Get.lazyPut<MarketplaceRepository>(
        () => MarketplaceRepository(),
        fenix: true,
      );
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
