import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../repository/marketplace_repository.dart';

/// CartController — Manages the farmer's shopping cart and checkout
class CartController extends GetxController {
  final MarketplaceRepository _service = Get.find<MarketplaceRepository>();
  final AuthRepository _auth = Get.find<AuthRepository>();

  // ── State ──
  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isPlacingOrder = false.obs;

  // ── Checkout form ──
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // ── Computed ──
  double get subtotal =>
      cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee =>
      cartItems.isEmpty ? 0 : MarketplaceRepository.deliveryFee;

  double get totalAmount => subtotal + deliveryFee;

  int get itemCount => cartItems.length;

  String? get _uid => _auth.currentUser.value?.uid;

  @override
  void onInit() {
    super.onInit();
    // Pre-fill phone from profile
    final user = _auth.currentUser.value;
    if (user != null) {
      phoneController.text = user.phone;
      addressController.text = user.location ?? '';
    }
    loadCart();
  }

  // ═══════════════════════════════════════════
  //  CART OPERATIONS
  // ═══════════════════════════════════════════

  /// Load cart from Firestore and enrich with product data
  Future<void> loadCart() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      isLoading.value = true;
      final rawItems = await _service.fetchCartItems(uid);
      final List<CartItemModel> enriched = [];

      for (final raw in rawItems) {
        final product = await _service.fetchProductById(
          raw['productId'] as String,
        );
        if (product != null && product.isActive) {
          enriched.add(
            CartItemModel(
              productId: product.id,
              productName: product.name,
              sellerName: product.sellerName,
              sellerId: product.sellerId,
              price: product.price,
              imageUrl: product.imageUrl,
              quantity: raw['quantity'] as int? ?? 1,
              availableStock: product.stock,
            ),
          );
        } else {
          // Product deleted / deactivated — remove from cart silently
          await _service.removeCartItem(uid, raw['productId'] as String);
        }
      }
      cartItems.assignAll(enriched);
    } catch (e) {
      debugPrint('[CartController] loadCart error: $e');
      AppSnackbar.error('Unable to load cart.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Add a product to cart (or increment quantity)
  /// Only non-company users can add to cart
  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    // Role guard: companies cannot buy
    final userType = _auth.currentUser.value?.userType ?? '';
    if (userType == 'company') {
      AppSnackbar.warning('Sellers cannot purchase products.');
      return;
    }

    final uid = _uid;
    if (uid == null) {
      AppSnackbar.warning('Please log in to add items to cart.');
      return;
    }

    // Check stock
    if (quantity > product.stock) {
      AppSnackbar.warning('Only ${product.stock} items available.');
      return;
    }

    try {
      // Check if already in cart
      final idx = cartItems.indexWhere((c) => c.productId == product.id);
      int newQty = quantity;
      if (idx >= 0) {
        newQty = cartItems[idx].quantity + quantity;
        if (newQty > product.stock) {
          AppSnackbar.warning(
            'Cannot add more. Only ${product.stock} in stock.',
          );
          return;
        }
      }

      await _service.setCartItem(uid, product.id, newQty);

      // Update local state
      if (idx >= 0) {
        cartItems[idx] = cartItems[idx].copyWith(quantity: newQty);
      } else {
        cartItems.add(
          CartItemModel(
            productId: product.id,
            productName: product.name,
            sellerName: product.sellerName,
            sellerId: product.sellerId,
            price: product.price,
            imageUrl: product.imageUrl,
            quantity: newQty,
            availableStock: product.stock,
          ),
        );
      }
      cartItems.refresh();
      AppSnackbar.success('Added to cart!');
    } catch (e) {
      debugPrint('[CartController] addToCart error: $e');
      AppSnackbar.error('Failed to add to cart.');
    }
  }

  /// Update quantity of a cart item
  Future<void> updateQuantity(String productId, int newQty) async {
    final uid = _uid;
    if (uid == null) return;

    final idx = cartItems.indexWhere((c) => c.productId == productId);
    if (idx < 0) return;

    if (newQty <= 0) {
      await removeItem(productId);
      return;
    }

    if (newQty > cartItems[idx].availableStock) {
      AppSnackbar.warning('Only ${cartItems[idx].availableStock} available.');
      return;
    }

    try {
      await _service.setCartItem(uid, productId, newQty);
      cartItems[idx] = cartItems[idx].copyWith(quantity: newQty);
      cartItems.refresh();
    } catch (e) {
      debugPrint('[CartController] updateQuantity error: $e');
    }
  }

  /// Remove an item from cart
  Future<void> removeItem(String productId) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _service.removeCartItem(uid, productId);
      cartItems.removeWhere((c) => c.productId == productId);
      AppSnackbar.info('Item removed from cart.');
    } catch (e) {
      debugPrint('[CartController] removeItem error: $e');
    }
  }

  // ═══════════════════════════════════════════
  //  CHECKOUT
  // ═══════════════════════════════════════════

  /// Validate checkout form
  bool _validateCheckout() {
    if (cartItems.isEmpty) {
      AppSnackbar.warning('Your cart is empty.');
      return false;
    }
    if (addressController.text.trim().isEmpty) {
      AppSnackbar.warning('Please enter your delivery address.');
      return false;
    }
    if (phoneController.text.trim().isEmpty ||
        phoneController.text.trim().length < 11) {
      AppSnackbar.warning('Please enter a valid phone number.');
      return false;
    }
    return true;
  }

  /// Place a COD order (farmer only)
  Future<void> placeOrder() async {
    if (isPlacingOrder.value) return;

    // Role guard: companies cannot place orders
    final userType = _auth.currentUser.value?.userType ?? '';
    if (userType == 'company') {
      AppSnackbar.warning('Sellers cannot place orders.');
      return;
    }

    if (!_validateCheckout()) return;

    final uid = _uid;
    final user = _auth.currentUser.value;
    if (uid == null || user == null) return;

    try {
      isPlacingOrder.value = true;

      // Re-validate stock from server
      for (final item in cartItems) {
        final fresh = await _service.fetchProductById(item.productId);
        if (fresh == null || !fresh.isActive) {
          AppSnackbar.error('${item.productName} is no longer available.');
          await loadCart();
          return;
        }
        if (fresh.stock < item.quantity) {
          AppSnackbar.error(
            '${item.productName} only has ${fresh.stock} left in stock.',
          );
          await loadCart();
          return;
        }
      }

      // Build order items list
      final orderItems = cartItems.map((c) => c.toOrderItem()).toList();

      final order = OrderModel(
        id: '',
        buyerId: uid,
        buyerName: user.name,
        items: orderItems,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        totalAmount: totalAmount,
        deliveryAddress: addressController.text.trim(),
        phone: phoneController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _service.createOrder(order);

      // Clear cart in Firestore and locally
      await _service.clearCart(uid);
      cartItems.clear();

      AppSnackbar.success('Order placed! Pay when delivered.');
      Get.back(); // return from checkout
      Get.back(); // return from cart
    } catch (e) {
      debugPrint('[CartController] placeOrder error: $e');
      AppSnackbar.error('Failed to place order. Please try again.');
    } finally {
      isPlacingOrder.value = false;
    }
  }

  @override
  void onClose() {
    addressController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
