import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/data/services/cloudinary_service.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../repository/marketplace_repository.dart';

/// SellerController — Handles company/seller product management & orders
class SellerController extends GetxController {
  final MarketplaceRepository _service = Get.find<MarketplaceRepository>();
  final AuthRepository _auth = Get.find<AuthRepository>();
  final CloudinaryService _cloudinary = Get.find<CloudinaryService>();

  // ── Product management state ──
  final RxList<ProductModel> myProducts = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUploading = false.obs;

  // ── Add / Edit product form ──
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final RxString selectedCategory = 'seeds'.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxString imageUrl = ''.obs;
  String? _editingProductId; // null = creating new

  // ── Orders state ──
  final RxList<OrderModel> sellerOrders = <OrderModel>[].obs;
  final RxBool isLoadingOrders = false.obs;

  String? get _uid => _auth.currentUser.value?.uid;
  String get _sellerName =>
      _auth.currentUser.value?.companyName ??
      _auth.currentUser.value?.name ??
      '';

  @override
  void onInit() {
    super.onInit();
    loadMyProducts();
  }

  // ═══════════════════════════════════════════
  //  PRODUCT MANAGEMENT
  // ═══════════════════════════════════════════

  /// Load products owned by the current seller
  Future<void> loadMyProducts() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      isLoading.value = true;
      final list = await _service.fetchSellerProducts(uid);
      myProducts.assignAll(list);
    } catch (e) {
      debugPrint('[SellerController] loadMyProducts error: $e');
      AppSnackbar.error('Unable to load your products.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Prepare the form for adding a new product
  void prepareNewProduct() {
    _editingProductId = null;
    nameCtrl.clear();
    priceCtrl.clear();
    stockCtrl.clear();
    descCtrl.clear();
    selectedCategory.value = 'seeds';
    selectedImage.value = null;
    imageUrl.value = '';
  }

  /// Prepare the form for editing an existing product
  void prepareEditProduct(ProductModel p) {
    _editingProductId = p.id;
    nameCtrl.text = p.name;
    priceCtrl.text = p.price.toStringAsFixed(0);
    stockCtrl.text = p.stock.toString();
    descCtrl.text = p.description;
    selectedCategory.value = p.category;
    selectedImage.value = null;
    imageUrl.value = p.imageUrl;
  }

  /// Pick image from gallery
  Future<void> pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        selectedImage.value = File(picked.path);
      }
    } catch (e) {
      debugPrint('[SellerController] pickImage error: $e');
    }
  }

  /// Validate and save product (create or update)
  Future<void> saveProduct() async {
    if (isSaving.value) return;
    if (!_validateProductForm()) return;

    final uid = _uid;
    if (uid == null) return;

    try {
      isSaving.value = true;

      // Upload image if a new one was selected
      String finalImageUrl = imageUrl.value;
      if (selectedImage.value != null) {
        isUploading.value = true;
        final url = await _cloudinary.uploadImage(
          selectedImage.value!,
          folder: 'product_images',
        );
        isUploading.value = false;
        if (url == null) {
          AppSnackbar.error('Image upload failed.');
          return;
        }
        finalImageUrl = url;
      }

      if (_editingProductId == null) {
        // ── CREATE ──
        final product = ProductModel(
          id: '',
          sellerId: uid,
          sellerName: _sellerName,
          name: nameCtrl.text.trim(),
          category: selectedCategory.value,
          price: double.parse(priceCtrl.text.trim()),
          stock: int.parse(stockCtrl.text.trim()),
          description: descCtrl.text.trim(),
          imageUrl: finalImageUrl,
          isActive: true,
          createdAt: DateTime.now(),
        );
        await _service.createProduct(product);
        AppSnackbar.success('Product added!');
      } else {
        // ── UPDATE ──
        await _service.updateProduct(_editingProductId!, {
          'name': nameCtrl.text.trim(),
          'category': selectedCategory.value,
          'price': double.parse(priceCtrl.text.trim()),
          'stock': int.parse(stockCtrl.text.trim()),
          'description': descCtrl.text.trim(),
          'imageUrl': finalImageUrl,
        });
        AppSnackbar.success('Product updated!');
      }

      await loadMyProducts();
      Get.back();
    } catch (e) {
      debugPrint('[SellerController] saveProduct error: $e');
      AppSnackbar.error('Failed to save product.');
    } finally {
      isSaving.value = false;
      isUploading.value = false;
    }
  }

  bool _validateProductForm() {
    if (nameCtrl.text.trim().isEmpty) {
      AppSnackbar.warning('Product name is required.');
      return false;
    }
    final price = double.tryParse(priceCtrl.text.trim());
    if (price == null || price <= 0) {
      AppSnackbar.warning('Enter a valid price.');
      return false;
    }
    final stock = int.tryParse(stockCtrl.text.trim());
    if (stock == null || stock < 0) {
      AppSnackbar.warning('Enter a valid stock quantity.');
      return false;
    }
    if (descCtrl.text.trim().isEmpty) {
      AppSnackbar.warning('Description is required.');
      return false;
    }
    // Image required for new product
    if (_editingProductId == null &&
        selectedImage.value == null &&
        imageUrl.value.isEmpty) {
      AppSnackbar.warning('Please add a product image.');
      return false;
    }
    return true;
  }

  /// Toggle product active / inactive
  Future<void> toggleActive(ProductModel p) async {
    try {
      await _service.updateProduct(p.id, {'isActive': !p.isActive});
      await loadMyProducts();
      AppSnackbar.info(
        p.isActive ? 'Product hidden from buyers.' : 'Product is now active.',
      );
    } catch (e) {
      AppSnackbar.error('Failed to update product.');
    }
  }

  /// Delete a product permanently
  Future<void> deleteProduct(ProductModel p) async {
    try {
      await _service.deleteProduct(p.id);
      myProducts.removeWhere((x) => x.id == p.id);
      AppSnackbar.success('Product deleted.');
    } catch (e) {
      AppSnackbar.error('Failed to delete product.');
    }
  }

  // ═══════════════════════════════════════════
  //  SELLER ORDERS
  // ═══════════════════════════════════════════

  /// Load orders that contain items sold by this seller
  Future<void> loadSellerOrders() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      isLoadingOrders.value = true;
      final all = await _service.fetchAllOrders();
      // Client-side filter: keep orders where any item.sellerId == me
      final filtered = all.where((order) {
        return order.items.any((item) => item['sellerId'] == uid);
      }).toList();
      sellerOrders.assignAll(filtered);
    } catch (e) {
      debugPrint('[SellerController] loadSellerOrders error: $e');
      AppSnackbar.error('Unable to load orders.');
    } finally {
      isLoadingOrders.value = false;
    }
  }

  /// Update order status (seller flow: confirmed → shipped → delivered)
  Future<void> updateOrderStatus(OrderModel order, String newStatus) async {
    try {
      await _service.updateOrderStatus(order.id, newStatus);

      // When confirming: reduce stock
      if (newStatus == 'confirmed') {
        final uid = _uid;
        // Only reduce stock for items belonging to this seller
        final myItems = order.items
            .where((item) => item['sellerId'] == uid)
            .toList();
        await _service.reduceStock(myItems);
      }

      await loadSellerOrders();
      AppSnackbar.success('Order status updated to $newStatus.');
    } catch (e) {
      debugPrint('[SellerController] updateOrderStatus error: $e');
      AppSnackbar.error('Failed to update order status.');
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    descCtrl.dispose();
    super.onClose();
  }
}
