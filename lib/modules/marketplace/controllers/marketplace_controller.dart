import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/product_model.dart';
import '../services/marketplace_service.dart';

/// MarketplaceController — Handles product browsing, search, category filter
class MarketplaceController extends GetxController {
  final MarketplaceService _service = Get.find<MarketplaceService>();

  // ── State ──
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedCategory = ''.obs; // empty = All
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  // ── Selected product for detail view ──
  final Rx<ProductModel?> selectedProduct = Rx<ProductModel?>(null);

  /// Current user type shortcut
  String get userType =>
      Get.find<AuthProvider>().currentUser.value?.userType ?? '';

  bool get isSeller => userType == 'company';

  @override
  void onInit() {
    super.onInit();
    // Debounced search
    debounce(
      searchQuery,
      (_) => loadProducts(),
      time: const Duration(milliseconds: 400),
    );
    loadProducts();
  }

  /// Load products from Firestore with current filters
  Future<void> loadProducts() async {
    try {
      isLoading.value = true;
      final cat = selectedCategory.value.isNotEmpty
          ? selectedCategory.value
          : null;
      final results = await _service.fetchProducts(
        category: cat,
        searchQuery: searchQuery.value,
      );
      products.assignAll(results);
    } catch (e) {
      debugPrint('[MarketplaceController] loadProducts error: $e');
      AppSnackbar.error('Unable to load products.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Set category filter and reload
  void setCategory(String category) {
    if (selectedCategory.value == category) {
      selectedCategory.value = ''; // toggle off
    } else {
      selectedCategory.value = category;
    }
    loadProducts();
  }

  /// Called when search text changes
  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  /// Select a product for detail view
  void openProductDetail(ProductModel product) {
    selectedProduct.value = product;
    Get.toNamed('/marketplace/product');
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
