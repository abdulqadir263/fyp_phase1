import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/order_model.dart';
import '../repository/marketplace_repository.dart';

/// OrderController — Manages buyer order history & selected order for detail view
class OrderController extends GetxController {
  final MarketplaceRepository _service = Get.find<MarketplaceRepository>();
  final AuthRepository _auth = Get.find<AuthRepository>();

  // ── State ──
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxBool isLoading = false.obs;

  // ── Selected order for detail / tracking ──
  final Rx<OrderModel?> selectedOrder = Rx<OrderModel?>(null);

  String? get _uid => _auth.currentUser.value?.uid;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  /// Load all buyer orders (permanent history — all time)
  Future<void> loadOrders() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      isLoading.value = true;
      final result = await _service.fetchBuyerOrders(uid);
      orders.assignAll(result);
    } catch (e) {
      debugPrint('[OrderController] loadOrders error: $e');
      AppSnackbar.error('Unable to load your orders.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Open order detail / tracking view
  void openOrderDetail(OrderModel order) {
    selectedOrder.value = order;
    Get.toNamed('/marketplace/orders/detail');
  }

  /// Get a live stream for the selected order (status tracking)
  Stream<OrderModel?> get orderStream {
    final id = selectedOrder.value?.id;
    if (id == null || id.isEmpty) return const Stream.empty();
    return _service.streamOrder(id);
  }
}
